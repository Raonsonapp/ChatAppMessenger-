'use strict';

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

/** Ҳадди Agora барои номи канал. */
const MAX_CHANNEL_BYTES = 64;

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
 * uid барои token ва барои `joinChannel`.
 *
 * ҲАРДУ бояд АЙНАН ЯКХЕЛА бошанд, вагарна Agora token-ро рад мекунад ва
 * занг бо хатои «token нодуруст» меафтад — маҳз ҳамин хатои аз ҳама
 * маъмул аст.
 *
 * 0 истифода мешавад: token ба канал баста мешавад, на ба корбар. Ин роҳи
 * санҷидашуда аст ва як синфи томи хатогиро — номувофиқатии uid — тамоман
 * барҳам медиҳад.
 *
 * Ин ҳимояро суст намекунад: token танҳо ба корбари ИҶОЗАТДОДАШУДА дода
 * мешавад (ниг. `checkChannelAccess`) ва як соат эътибор дорад.
 */
const CHANNEL_BOUND_UID = 0;

/**
 * Token барои канал.
 *
 * @param {string} channelName номи канал
 * @param {string} firebaseUid корбар
 * @returns {{token: string|null, appId: string, uid: number, expiresInSeconds: number}}
 */
function buildToken(channelName, firebaseUid) {
  if (!hasAppId()) throw new Error('AGORA_APP_ID гузошта нашудааст');

  // Agora номи каналро то 64 байт қабул мекунад. Номи дарозтар хомӯшона рад
  // мешавад ва ҳарду тараф то абад «Пайваст мешавад…» мебинанд.
  if (Buffer.byteLength(channelName) > MAX_CHANNEL_BYTES) {
    throw new Error('Номи канал аз 64 байт дарозтар аст');
  }

  const uid = CHANNEL_BOUND_UID;

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

/**
 * Оё ин корбар ҳақ дорад ба ин канал дарояд?
 *
 * Бе ин санҷиш ҳар корбари воридшуда метавонист барои ҲАР канал token гирад
 * ва ба сӯҳбати бегона гӯш кунад.
 *
 * Сабаб баргардонда мешавад, на танҳо «ҳа/не»: вақте занг кор намекунад,
 * «token нашуд» ҳељ чиз намефаҳмонад, вале «ҳуҷҷати занг ёфт нашуд» маҳз он
 * чизест, ки ҷустан лозим аст.
 *
 * @returns {Promise<{allowed: boolean, reason: string}>}
 */
async function checkChannelAccess(db, uid, channelName) {
  const groupId = groupIdFromChannel(channelName);

  if (groupId) {
    const group = await db.collection('groups').doc(groupId).get();
    if (!group.exists) return { allowed: false, reason: 'group-not-found' };
    const members = group.data()?.members;
    if (!Array.isArray(members) || !members.includes(uid)) {
      return { allowed: false, reason: 'not-a-member' };
    }
    return { allowed: true, reason: 'group-member' };
  }

  const call = await db.collection('calls').doc(channelName).get();
  if (!call.exists) return { allowed: false, reason: 'call-not-found' };
  const participants = call.data()?.participants;
  if (!Array.isArray(participants) || !participants.includes(uid)) {
    return { allowed: false, reason: 'not-a-participant' };
  }
  return { allowed: true, reason: 'call-participant' };
}

module.exports = {
  isConfigured,
  hasAppId,
  status,
  buildToken,
  groupIdFromChannel,
  checkChannelAccess,
  TOKEN_TTL_SECONDS,
  MAX_CHANNEL_BYTES,
};
