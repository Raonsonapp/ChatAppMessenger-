require('dotenv').config();

const crypto = require('node:crypto');

const express = require('express');
const cors = require('cors');
const { Telegraf, Markup } = require('telegraf');
const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

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
    publicDomain: process.env.PUBLIC_URL || process.env.RAILWAY_PUBLIC_DOMAIN || null,
  });
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

  const { toUid, title, body, data } = req.body ?? {};
  if (!toUid || !body) return res.status(400).json({ error: 'toUid va body lozimand' });

  // Ба худи худ огоҳинома намефиристем.
  if (toUid === sender.uid) return res.json({ sent: false, reason: 'self' });

  const doc = await getFirestore().collection('users').doc(toUid).get();
  const fcmToken = doc.data()?.fcmToken;
  if (!fcmToken) return res.json({ sent: false, reason: 'no-token' });

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
}

start();
