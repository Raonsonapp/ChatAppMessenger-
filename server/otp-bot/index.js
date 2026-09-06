require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { Telegraf, Markup } = require('telegraf');
const admin = require('firebase-admin');

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
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

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

bot.start((ctx) => {
  ctx.reply(
    'Хуш омадед! Барои гирифтани рамзи 6-рақамаи вуруд ба ChatApp, тугмаи зерро пахш карда рақами телефони худро мубодила кунед.',
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

  await ctx.reply(
    `Рамзи шумо: ${code}\n\nИн рамзро дар барномаи ChatApp ворид кунед. Рамз то 5 дақиқа эътибор дорад.`,
    Markup.removeKeyboard(),
  );
});

bot.catch((err) => {
  console.error('Хатои бот:', err);
});

bot.launch();
console.log('Telegram бот бо тарзи polling оғоз ёфт.');

// ---------- REST API барои апп ----------

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (_req, res) => {
  res.json({ ok: true, service: 'chatapp-otp-bot' });
});

app.post('/api/otp/verify', async (req, res) => {
  const { phone, code } = req.body ?? {};
  if (!phone || !code) {
    return res.status(400).json({ error: 'phone ва code лозиманд' });
  }

  const normalizedPhone = normalizePhone(phone);
  const entry = otpStore.get(normalizedPhone);

  if (!entry) {
    return res.status(400).json({ error: 'Аввал рамзро тавассути бот дархост кунед' });
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
  const token = await admin.auth().createCustomToken(uid, { phone: normalizedPhone });

  res.json({ token, uid, phone: normalizedPhone });
});

app.listen(PORT, () => {
  console.log(`OTP REST API дар порти ${PORT} кор мекунад.`);
});
