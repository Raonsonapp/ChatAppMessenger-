'use strict';

const crypto = require('node:crypto');
const { RtcTokenBuilder, RtcRole } = require('agora-token');

/**
 * Agora RTC — token барои занги садоӣ ва видеоӣ.
 *
 * App Certificate калиди махфист: агар он дар барнома гузошта шавад, онро аз
 * APK кашида гирифтан мумкин аст ва ҳар кас метавонад бо ҳисоби мо занг
 * занад. Бинобар ин token ҳамеша дар сервер сохта мешавад.
 */

/** Якчанд номи маъмули тағйирёбандаҳо дастгирӣ мешавад. */
function pick(...names) {
  for (const name of names) {
    const value = process.env[name];
    if (value && String(value).trim()) return String(value).trim();
  }
  return null;
}

const config = {
  appId: pick('AGORA_APP_ID', 'AGORA_APPID', 'AGORA_ID'),
  appCertificate: pick(
    'AGORA_APP_CERTIFICATE',
    'AGORA_CERTIFICATE',
    'AGORA_APP_CERT',
    'AGORA_PRIMARY_CERTIFICATE',
  ),
};

/** Мӯҳлати token — як соат. Занги дарозтар token-и навро мегирад. */
const TOKEN_TTL_SECONDS = 60 * 60;

function hasAppId() {
  return Boolean(config.appId);
}

/**
 * `true` — агар token сохта шавад.
 *
 * Бе Certificate занг ҳам кор мекунад, вале танҳо агар лоиҳаи Agora дар
 * ҳолати «App ID only» бошад.
 */
function isConfigured() {
  return Boolean(config.appId && config.appCertificate);
}

/**
 * Ҳолати танзимот — БЕ ҲЕҶ СИРРЕ.
 *
 * Танҳо номҳои тағйирёбандаҳои ба Agora монанд нишон дода мешаванд, то
 * номувофиқатии номро дидан мумкин бошад. Қиматҳо ҳељ гоҳ.
 */
function status() {
  const seen = Object.keys(process.env)
    .filter((name) => /AGORA/i.test(name))
    .sort();

  return {
    seenVariableNames: seen,
    hasAppId: hasAppId(),
    hasCertificate: Boolean(config.appCertificate),
    // Бо token — усули дуруст. Бе он — танҳо «App ID only».
    mode: isConfigured() ? 'token' : hasAppId() ? 'app-id-only' : 'not-configured',
    // App ID сир нест: он дар ҳар барномаи муштарӣ мавҷуд аст.
    appId: config.appId,
  };
}

/**
 * Аз uid-и Firebase рақами устувори 32-бита месозад.
 *
 * Agora uid-и рақамӣ талаб мекунад. Он бояд устувор бошад: агар ҳар бор
 * рақами нав дода шавад, token ба корбари дигар баста мешавад.
 * 0 гузошта намешавад — дар Agora он маънои «ҳар корбар»-ро дорад, яъне
 * token-и умумӣ мешавад ва ҳимояи худро гум мекунад.
 */
function numericUid(firebaseUid) {
  const hash = crypto.createHash('sha256').update(String(firebaseUid)).digest();
  // 31 бит — то дар доираи int32-и мусбат монад.
  const value = hash.readUInt32BE(0) & 0x7fffffff;
  return value === 0 ? 1 : value;
}

/**
 * Token барои канал.
 *
 * @param {string} channelName номи канал
 * @param {string} firebaseUid корбар
 * @returns {{token: string|null, appId: string, uid: number, expiresInSeconds: number}}
 */
function buildToken(channelName, firebaseUid) {
  if (!hasAppId()) throw new Error('AGORA_APP_ID гузошта нашудааст');

  const uid = numericUid(firebaseUid);

  // Бе Certificate token лозим нест ва сохта ҳам намешавад.
  if (!config.appCertificate) {
    return { token: null, appId: config.appId, uid, expiresInSeconds: 0 };
  }

  const token = RtcTokenBuilder.buildTokenWithUid(
    config.appId,
    config.appCertificate,
    channelName,
    uid,
    RtcRole.PUBLISHER,
    TOKEN_TTL_SECONDS,
    TOKEN_TTL_SECONDS,
  );

  return { token, appId: config.appId, uid, expiresInSeconds: TOKEN_TTL_SECONDS };
}

/**
 * Аз номи канали гурӯҳӣ id-и гурӯҳро мегирад.
 *
 * Шакл: `group_<groupId>_<вақт>`. Вақт ҳамеша рақам аст, бинобар ин ҳатто
 * агар id-и гурӯҳ хати поёнӣ дошта бошад, дуруст ҷудо мешавад.
 *
 * @returns {string|null}
 */
function groupIdFromChannel(channelName) {
  const match = /^group_(.+)_\d+$/.exec(channelName);
  return match ? match[1] : null;
}

module.exports = {
  isConfigured,
  hasAppId,
  status,
  buildToken,
  numericUid,
  groupIdFromChannel,
  TOKEN_TTL_SECONDS,
};
