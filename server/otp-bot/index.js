require('dotenv').config();

const crypto = require('node:crypto');

const express = require('express');
const cors = require('cors');
const { Telegraf, Markup } = require('telegraf');
const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const r2 = require('./r2');
const { overQuota } = require('./quota');

/** Вақти оғози ин нусхаи сервер. */
const startedAt = new Date();

const BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || process.env.BOT_TOKEN;
const PORT = process.env.PORT || 3000;
const CODE_TTL_MS = 5 * 60 * 1000; // 5 дақиқа
const RESEND_COOLDOWN_MS = 60 * 1000; // 60 сония

if (!BOT_TOKEN) {
  console.error('TELEGRAM_BOT_TOKEN муайян нашудааст (.env ё Railway variables-ро тафтиш кунед).');
  process.exit(1);
}

// firebase-admin ФАҚАТ барои сохтани custom token лозим аст (то signInWithCustomToken
// дар апп корбарро ба ҳамон системаи Firebase Auth ворид кунад, ки Firestore/Storage
// қоидаҳояшон ба он такя мекунанд) — на барои фиристодани SMS.
// Ду тарз дастгирӣ мешавад: рост JSON (нусхабардорӣ аз файли боргирифташуда,
// осонтар) ё base64 (агар пештара ҳамин тавр гузошта бошӣ).
const rawServiceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
const serviceAccountBase64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
if (!rawServiceAccountJson && !serviceAccountBase64) {
  console.error('FIREBASE_SERVICE_ACCOUNT_JSON (ё FIREBASE_SERVICE_ACCOUNT_BASE64) муайян нашудааст.');
  process.exit(1);
}
const serviceAccount = rawServiceAccountJson
  ? JSON.parse(rawServiceAccountJson)
  : JSON.parse(Buffer.from(serviceAccountBase64, 'base64').toString('utf8'));
initializeApp({ credential: cert(serviceAccount) });

/** phone (E.164, e.g. "+992901234567") -> { code, expiresAt, lastSentAt, chatId } */
const otpStore = new Map();

function normalizePhone(raw) {
  const digits = String(raw).replace(/[^0-9]/g, '');
  return `+${digits}`;
}

function generateCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function uidForPhone(phone) {
  return `phone_${phone.replace(/[^0-9]/g, '')}`;
}

// ---------- Telegram bot ----------

const bot = new Telegraf(BOT_TOKEN);

/** chatId -> рақаме, ки барнома интизор аст (аз payload-и линки `?start=`) */
const expectedPhoneByChat = new Map();

bot.start((ctx) => {
  // Барнома рақамро ҳамчун payload мефиристад: t.me/<bot>?start=992XXXXXXXX
  const payloadDigits = String(ctx.startPayload ?? '').replace(/[^0-9]/g, '');
  let hint = '';
  if (payloadDigits) {
    const expected = `+${payloadDigits}`;
    expectedPhoneByChat.set(ctx.chat.id, expected);
    hint = `\n\nБарнома рақами ${expected}-ро интизор аст.`;
  }

  ctx.reply(
    'Хуш омадед! Барои гирифтани рамзи 6-рақамаи вуруд ба ChatApp, тугмаи зерро пахш карда рақами телефони худро мубодила кунед.' + hint,
    Markup.keyboard([Markup.button.contactRequest('📱 Фиристодани рақами телефон')])
      .resize()
      .oneTime(),
  );
});

bot.on('contact', async (ctx) => {
  const contact = ctx.message.contact;

  // Танҳо рақами худи корбар (на рақами фиристодашуда аз каси дигар) қабул мешавад.
  if (contact.user_id && contact.user_id !== ctx.from.id) {
    ctx.reply('Лутфан рақами телефони ХУДи худро фиристед, на дигарро.');
    return;
  }

  const phone = normalizePhone(contact.phone_number);
  const now = Date.now();
  const existing = otpStore.get(phone);

  if (existing && now - existing.lastSentAt < RESEND_COOLDOWN_MS) {
    const waitSec = Math.ceil((RESEND_COOLDOWN_MS - (now - existing.lastSentAt)) / 1000);
    ctx.reply(`Лутфан ${waitSec} сония сабр кунед, пеш аз дархости рамзи нав.`);
    return;
  }

  const code = generateCode();
  otpStore.set(phone, {
    code,
    expiresAt: now + CODE_TTL_MS,
    lastSentAt: now,
    chatId: ctx.chat.id,
  });

  // Агар корбар дар барнома як рақам нависаду дар бот рақами дигарро мубодила
  // кунад, сервер рамзро намеёбад. Инро дарҳол равшан мегӯем.
  const expected = expectedPhoneByChat.get(ctx.chat.id);
  const mismatchNote =
    expected && expected !== phone
      ? `\n\n⚠️ Дар барнома ${expected} навишта шудааст, вале шумо ${phone}-ро мубодила кардед. Дар барнома маҳз ${phone}-ро нависед.`
      : '';

  await ctx.reply(
    `Рамзи шумо: ${code}\n\nИн рамзро дар барномаи ChatApp ворид кунед. Рамз то 5 дақиқа эътибор дорад.${mismatchNote}`,
    Markup.removeKeyboard(),
  );
});

bot.catch((err) => {
  console.error('Хатои бот:', err);
});

// Дар ҳолати polling, launch() то охири кори бот resolve намешавад. Агар
// reject шавад, бояд фарқ кунем:
//   401 — токен нодуруст аст, такрор фоида надорад.
//   409 — контейнери кӯҳна ҳанӯз getUpdates мекунад (ҳангоми deploy якчанд
//         сония ҳарду зинда мемонанд). Ин муваққатист — бояд такрор кунем,
//         вагарна ҳар deploy ботро то абад мекушад.
async function launchBotWithRetry() {
  for (let attempt = 1; ; attempt += 1) {
    try {
      await bot.launch();
      return;
    } catch (err) {
      if (err?.response?.error_code === 401) {
        console.error('Telegram токенро қабул накард (401).');
        console.error('TELEGRAM_BOT_TOKEN-ро тафтиш кунед (@BotFather).');
        process.exit(1);
      }
      const waitMs = Math.min(30_000, 2_000 * attempt);
      console.error(`Оғози бот муваффақ нашуд: ${err?.message ?? err}`);
      console.error(`Такрори кӯшиш пас аз ${waitMs / 1000} сония...`);
      await new Promise((resolve) => setTimeout(resolve, waitMs));
    }
  }
}

// ---------- REST API барои апп ----------

const app = express();
app.use(cors());
app.use(express.json());

// Ҳолати бот, то бидуни логҳои Railway ҳам фаҳмидан мумкин бошад, ки бот дар
// кадом усул кор мекунад ва чаро.
const botStatus = { mode: 'оғоз нашуда', detail: null };

app.get('/', (_req, res) => {
  res.json({
    ok: true,
    service: 'chatapp-otp-bot',
    bot: botStatus,
    // Ҳолати анбори файлҳо — бе ҳељ сирре, танҳо «ҳаст/нест».
    storage: { ...r2.status(), selfTest: r2.lastSelfTest() },
    publicDomain: process.env.PUBLIC_URL || process.env.RAILWAY_PUBLIC_DOMAIN || null,
    // Кадом нусхаи код кор мекунад — барои санҷиши он ки деплой расидааст ё не.
    build: {
      commit: (process.env.RAILWAY_GIT_COMMIT_SHA || '').slice(0, 7) || null,
      startedAt: startedAt.toISOString(),
    },
  });
});

/**
 * Санҷиши анбор: файли хурд бор карда, аз домени ҷамъиятӣ хонда мешавад.
 * `?force=1` санҷишро аз нав иҷро мекунад.
 */
app.get('/api/storage-selftest', async (req, res) => {
  const force = req.query.force === '1' || req.query.force === 'true';
  const result = await r2.selfTest({ force });
  res.status(result.ok ? 200 : 503).json({ storage: r2.status(), selfTest: result });
});

/**
 * Ҳаволаи имзошуда барои боркунии файл ба R2.
 *
 * Барнома калидҳои R2-ро намедонад: он танҳо токени Firebase-и худро
 * мефиристад ва ҳаволаи кӯтоҳмуддат мегирад, баъд файлро бевосита ба R2
 * мефиристад. Ин ҳам бехатартар аст, ҳам трафики сервер сарф намешавад.
 */
/** Ҳадди ниҳоии андозаи як файл — 100 МБ. */
const MAX_UPLOAD_BYTES = 100 * 1024 * 1024;

/** Ҳадди дархостҳои боркунӣ барои як корбар дар як соат. */
const UPLOAD_QUOTA_PER_HOUR = 200;
const uploadQuota = new Map();

/**
 * Ҳадди огоҳиномаҳо барои як корбар дар як соат.
 *
 * Ин ҷо на дархостҳо, балки ГИРАНДАГОН ҳисоб мешаванд: як дархост ба 500
 * нафар аз як дархост ба як нафар хеле гаронтар аст, вагарна маҳдудиятро
 * бо як дархости калон давр задан мумкин мебуд.
 */
const NOTIFY_QUOTA_PER_HOUR = 3000;
const notifyQuota = new Map();

function quotaExceeded(uid) {
  return overQuota(uploadQuota, uid, UPLOAD_QUOTA_PER_HOUR);
}

app.post('/api/upload-url', async (req, res) => {
  const authHeader = req.headers.authorization || '';
  const idToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!idToken) return res.status(401).json({ error: 'Authorization lozim ast' });

  let user;
  try {
    user = await getAuth().verifyIdToken(idToken);
  } catch {
    return res.status(401).json({ error: 'Token nodurust ast' });
  }

  if (!r2.isConfigured()) {
    return res.status(503).json({ error: 'r2-not-configured', storage: r2.status() });
  }

  if (quotaExceeded(user.uid)) {
    return res.status(429).json({ error: 'too-many-uploads' });
  }

  const { folder, name, contentType, size } = req.body ?? {};
  if (!name) return res.status(400).json({ error: 'name lozim ast' });

  // Андоза ҳатмист ва ба имзо дохил мешавад: бо як ҳавола танҳо ҳамон
  // андоза бор карда мешавад, на бештар.
  const contentLength = Number(size);
  if (!Number.isInteger(contentLength) || contentLength <= 0) {
    return res.status(400).json({ error: 'size lozim ast' });
  }
  if (contentLength > MAX_UPLOAD_BYTES) {
    return res.status(413).json({ error: 'file-too-large', maxBytes: MAX_UPLOAD_BYTES });
  }

  // Роҳи файл: папка + uid + вақт + ном. uid дар роҳ мемонад, то маълум бошад
  // кӣ файлро бор кардааст.
  const safeFolder = String(folder || 'files').replace(/[^a-zA-Z0-9/_-]/g, '').replace(/^\/+|\/+$/g, '');
  const safeName = String(name).replace(/[^a-zA-Z0-9._-]/g, '_').slice(-80);
  const key = `${safeFolder || 'files'}/${user.uid}/${Date.now()}_${safeName}`;

  try {
    const signed = r2.presignPut(key, 900, { contentLength });
    res.json({ ...signed, contentType: contentType || 'application/octet-stream' });
  } catch (err) {
    console.error('Хатои сохтани ҳаволаи боркунӣ:', err?.message ?? err);
    res.status(500).json({ error: 'presign-failed' });
  }
});

app.post('/api/otp/verify', async (req, res) => {
  const { phone, code } = req.body ?? {};
  if (!phone || !code) {
    return res.status(400).json({ error: 'phone ва code лозиманд' });
  }

  const normalizedPhone = normalizePhone(phone);
  const entry = otpStore.get(normalizedPhone);

  if (!entry) {
    return res.status(400).json({
      error: 'Барои ин рақам рамз дархост нашудааст. Дар бот маҳз ҳамин рақамро мубодила кунед.',
    });
  }
  if (Date.now() > entry.expiresAt) {
    otpStore.delete(normalizedPhone);
    return res.status(400).json({ error: 'Мӯҳлати рамз гузаштааст. Рамзи нав дархост кунед' });
  }
  if (entry.code !== String(code).trim()) {
    return res.status(400).json({ error: 'Рамз нодуруст аст' });
  }

  // Якдафъаина — пас аз тасдиқи муваффақ рамз бекор мешавад.
  otpStore.delete(normalizedPhone);

  const uid = uidForPhone(normalizedPhone);
  const token = await getAuth().createCustomToken(uid, { phone: normalizedPhone });

  res.json({ token, uid, phone: normalizedPhone });
});

// ---------- Огоҳиномаҳои push ----------
//
// Cloud Functions барои триггери Firestore ба нақшаи Blaze ниёз дорад, бинобар
// ин барнома пас аз фиристодани паём худаш ин эндпоинтро даъво мекунад ва мо
// push мефиристем. Даъватгар бо ID token тасдиқ мешавад, то бегона ба ҳар кас
// огоҳинома фиристода натавонад.
/** Ҳадди FCM барои як дархости multicast. */
const FCM_MULTICAST_LIMIT = 500;

/** Ҳадди гирандагон дар як дархост — то касе серверро бор накунад. */
const NOTIFY_RECIPIENTS_LIMIT = 2000;

/**
 * Ба якчанд гиранда якбора огоҳинома мефиристад.
 *
 * Токенҳо дар як хониш гирифта мешаванд, фиристодан бо `sendEachForMulticast`
 * анҷом меёбад ва токенҳои бекоршуда фавран тоза карда мешаванд.
 */
async function notifyMany({ sender, toUids, title, body, data }) {
  const unique = [...new Set(toUids.map(String))]
    .filter((uid) => uid && uid !== sender.uid)
    .slice(0, NOTIFY_RECIPIENTS_LIMIT);

  if (unique.length === 0) return { sent: 0, skipped: 0 };

  const db = getFirestore();
  const refs = unique.map((uid) => db.collection('users').doc(uid));
  const docs = await db.getAll(...refs);

  /** @type {{token: string, ref: FirebaseFirestore.DocumentReference}[]} */
  const targets = [];
  let skipped = 0;
  for (const doc of docs) {
    const info = doc.data();
    // Огоҳиномаи хомӯшкарда ва корбари бе токен партофта мешаванд.
    if (!info?.fcmToken || info?.settings?.messageNotifications === false) {
      skipped += 1;
      continue;
    }
    targets.push({ token: info.fcmToken, ref: doc.ref });
  }

  if (targets.length === 0) return { sent: 0, skipped };

  const payload = {
    notification: { title: title || 'ChatApp', body },
    data: Object.fromEntries(
      Object.entries({ ...(data || {}), senderUid: sender.uid }).map(([k, v]) => [k, String(v)]),
    ),
    android: { priority: 'high' },
  };

  let sent = 0;
  const stale = [];

  for (let i = 0; i < targets.length; i += FCM_MULTICAST_LIMIT) {
    const chunk = targets.slice(i, i + FCM_MULTICAST_LIMIT);
    const response = await getMessaging().sendEachForMulticast({
      ...payload,
      tokens: chunk.map((t) => t.token),
    });

    response.responses.forEach((item, index) => {
      if (item.success) {
        sent += 1;
        return;
      }
      if (item.error?.code === 'messaging/registration-token-not-registered') {
        stale.push(chunk[index].ref);
      }
    });
  }

  // Токенҳои бекоршуда тоза мешаванд, то дафъаи дигар бекор кӯшиш нашавад.
  await Promise.all(
    stale.map((ref) => ref.update({ fcmToken: FieldValue.delete() }).catch(() => {})),
  );

  return { sent, skipped: skipped + (targets.length - sent) };
}

/**
 * Нест кардани ҳисоб бо ҳамаи маълумоти шахсӣ.
 *
 * Google Play талаб мекунад, ки корбар ҳисоби худро аз дохили барнома нест
 * карда тавонад. Ғайр аз ин, ин ҳаққи оддии корбар аст.
 *
 * Чӣ нест мешавад: профил, навсозиҳо (status), паёмҳои ситорадор, зангҳо,
 * узвият дар гурӯҳ ва ҷамъиятҳо, рамзҳои даъвати сохтаи ӯ ва худи ҳисоби
 * Firebase Auth.
 *
 * Чӣ боқӣ мемонад: паёмҳои дар чати дигарон навишташуда. Онҳо ба
 * муколамаи шахси дигар тааллуқ доранд ва нест кардани онҳо таърихи ӯро
 * вайрон мекунад — ҳамон тавре ки дар барномаҳои дигар аст.
 */
app.post('/api/delete-account', async (req, res) => {
  const authHeader = req.headers.authorization || '';
  const idToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!idToken) return res.status(401).json({ error: 'Authorization lozim ast' });

  let user;
  try {
    // `true` — токени бекоршуда низ рад мешавад: ин амал бозгашт надорад.
    user = await getAuth().verifyIdToken(idToken, true);
  } catch {
    return res.status(401).json({ error: 'Token nodurust ast' });
  }

  const uid = user.uid;
  const db = getFirestore();

  try {
    // 1. Навсозиҳо (status) бо ҳамаи бандҳояшон.
    const statusItems = await db.collection('statuses').doc(uid).collection('items').get();
    await deleteDocs(db, statusItems.docs.map((d) => d.ref));
    await db.collection('statuses').doc(uid).delete().catch(() => {});

    // 2. Паёмҳои ситорадор.
    const starred = await db.collection('users').doc(uid).collection('starred').get();
    await deleteDocs(db, starred.docs.map((d) => d.ref));

    // 3. Зангҳо — ҳам зангҳои кардашуда, ҳам қабулшуда.
    for (const field of ['callerId', 'calleeId']) {
      const calls = await db.collection('calls').where(field, '==', uid).get();
      await deleteDocs(db, calls.docs.map((d) => d.ref));
    }

    // 4. Узвият дар гурӯҳҳо ва ҷамъиятҳо.
    for (const collection of ['groups', 'communities']) {
      const snap = await db.collection(collection).where('members', 'array-contains', uid).get();
      await Promise.all(
        snap.docs.map((doc) =>
          doc.ref
            .update({
              members: FieldValue.arrayRemove(uid),
              admins: FieldValue.arrayRemove(uid),
              [`memberNames.${uid}`]: FieldValue.delete(),
            })
            .catch(() => {}),
        ),
      );
    }

    // 5. Рамзҳои даъвате, ки худи ӯ сохтааст.
    const invites = await db.collection('groupInvites').where('createdBy', '==', uid).get();
    await deleteDocs(db, invites.docs.map((d) => d.ref));

    // 6. Профил.
    await db.collection('users').doc(uid).delete().catch(() => {});

    // 7. Худи ҳисоб. Ин охирин аст: агар қадамҳои боло ноком шаванд, корбар
    // ҳанӯз вориди барнома шуда, боз кӯшиш карда метавонад.
    await getAuth().deleteUser(uid);

    res.json({ deleted: true });
  } catch (err) {
    console.error('Хатои нест кардани ҳисоб:', err?.message ?? err);
    res.status(500).json({ error: 'hisob nest karda nashud' });
  }
});

/** Ҳуҷҷатҳоро бо бастаҳои 400-то нест мекунад (ҳадди Firestore 500 аст). */
async function deleteDocs(db, refs) {
  for (let i = 0; i < refs.length; i += 400) {
    const batch = db.batch();
    for (const ref of refs.slice(i, i + 400)) batch.delete(ref);
    await batch.commit().catch(() => {});
  }
}

app.post('/api/notify', async (req, res) => {
  const authHeader = req.headers.authorization || '';
  const idToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!idToken) return res.status(401).json({ error: 'Authorization lozim ast' });

  let sender;
  try {
    sender = await getAuth().verifyIdToken(idToken);
  } catch {
    return res.status(401).json({ error: 'Token nodurust ast' });
  }

  const { toUid, toUids, title, body, data } = req.body ?? {};

  // Арзиш аз рӯи шумораи гирандагон ҳисоб мешавад, на дархостҳо: вагарна
  // маҳдудиятро бо як дархости калон давр задан мумкин мебуд.
  const recipientCount = Array.isArray(toUids) ? Math.max(toUids.length, 1) : 1;
  if (overQuota(notifyQuota, sender.uid, NOTIFY_QUOTA_PER_HOUR, recipientCount)) {
    return res.status(429).json({ error: 'too-many-notifications' });
  }

  // Ҳолати гурӯҳӣ: як дархост ба ҷои даҳҳо. Барномаи телефон пештар барои
  // ҳар узв як дархости алоҳида мефиристод — дар гурӯҳи калон ин садҳо
  // дархост, вақт ва трафик буд.
  if (Array.isArray(toUids)) {
    if (!body) return res.status(400).json({ error: 'body lozim ast' });
    try {
      const result = await notifyMany({ sender, toUids, title, body, data });
      return res.json(result);
    } catch (err) {
      console.error('Хатои фиристодани push (гурӯҳӣ):', err?.message ?? err);
      return res.status(500).json({ error: 'push firistoda nashud' });
    }
  }

  if (!toUid || !body) return res.status(400).json({ error: 'toUid va body lozimand' });

  // Ба худи худ огоҳинома намефиристем.
  if (toUid === sender.uid) return res.json({ sent: false, reason: 'self' });

  const doc = await getFirestore().collection('users').doc(toUid).get();
  const fcmToken = doc.data()?.fcmToken;
  if (!fcmToken) return res.json({ sent: false, reason: 'no-token' });

  // Агар гиранда огоҳиномаи паёмро хомӯш карда бошад, чизе намефиристем —
  // вагарна танзимот танҳо дар экран менамуд ва ҳељ кор намекард.
  if (doc.data()?.settings?.messageNotifications === false) {
    return res.json({ sent: false, reason: 'muted' });
  }

  try {
    await getMessaging().send({
      token: fcmToken,
      notification: { title: title || 'ChatApp', body },
      data: Object.fromEntries(
        Object.entries({ ...(data || {}), senderUid: sender.uid }).map(([k, v]) => [k, String(v)]),
      ),
      android: { priority: 'high' },
    });
    res.json({ sent: true });
  } catch (err) {
    // Токени кӯҳна/бекоршуда — онро тоза мекунем, то бори дигар кӯшиш нашавад.
    if (err?.code === 'messaging/registration-token-not-registered') {
      await doc.ref.update({ fcmToken: FieldValue.delete() }).catch(() => {});
      return res.json({ sent: false, reason: 'stale-token' });
    }
    console.error('Хатои фиристодани push:', err?.message ?? err);
    res.status(500).json({ error: 'push firistoda nashud' });
  }
});

async function start() {
  // Агар домени ҷамъиятӣ маълум бошад (дар Railway — RAILWAY_PUBLIC_DOMAIN),
  // webhook беҳтар аз polling аст: Telegram худаш update мефиристад, ҳељ
  // getUpdates нест, пас хатои 409 "terminated by other getUpdates request"
  // ҳангоми deploy-и нав умуман ба вуҷуд намеояд.
  const publicDomain = process.env.PUBLIC_URL || process.env.RAILWAY_PUBLIC_DOMAIN;

  if (publicDomain) {
    // Роҳи худи telegraf аз hash-и (токен + версияи Node) сохта мешавад, яъне
    // ҳангоми навсозии Node тағйир меёбад. Роҳи худамон танҳо ба токен вобаста
    // аст — устувор мемонад ва ҳамчунон тахминнашаванда.
    const webhookPath =
      '/telegram/' + crypto.createHash('sha256').update(BOT_TOKEN).digest('hex').slice(0, 32);
    try {
      app.use(await bot.createWebhook({ domain: publicDomain, path: webhookPath }));
      botStatus.mode = 'webhook';
      botStatus.detail = `https://${publicDomain.replace(/^https?:\/\//, '')}${webhookPath}`;
      console.log(`Бот бо webhook кор мекунад: ${botStatus.detail}`);
    } catch (err) {
      botStatus.mode = 'polling';
      botStatus.detail = `насби webhook муваффақ нашуд: ${err?.message ?? err}`;
      console.error(botStatus.detail);
      console.error('Бозгашт ба polling.');
      launchBotWithRetry();
    }
  } else {
    botStatus.mode = 'polling';
    botStatus.detail = 'PUBLIC_URL ва RAILWAY_PUBLIC_DOMAIN ҳарду холӣ';
    console.log('Домени ҷамъиятӣ маълум нест — бот бо polling кор мекунад.');
    launchBotWithRetry();
  }

  // Ба 0.0.0.0 баста мешавад: бе ин Node ба '::' мебандад ва дар контейнер
  // метавонад танҳо IPv6-ро бигирад, дар ҳоле ки Railway тавассути IPv4 пайваст
  // мешавад — натиҷа 502 "Application failed to respond".
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`OTP REST API дар 0.0.0.0:${PORT} кор мекунад (PORT env = ${process.env.PORT ?? 'нест'}).`);
  });

  // Анборро якбора месанҷем, то хатогии танзим то кӯшиши аввалини корбар
  // маълум шавад. Ин ба оғози сервер халал намерасонад.
  if (r2.isConfigured()) {
    r2.selfTest()
      .then((result) => {
        console.log(
          result.ok
            ? 'R2: санҷиши анбор бомуваффақият гузашт.'
            : `R2: санҷиш нагузашт (${result.stage}): ${result.detail ?? ''}`,
        );
      })
      .catch(() => {});
  } else {
    console.log('R2: танзим нашудааст — бор кардани файл кор намекунад.');
  }
}

start();
