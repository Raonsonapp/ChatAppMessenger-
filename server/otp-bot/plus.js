'use strict';

/**
 * Мантиқи ChatApp Plus.
 *
 * Ин ҷо ҳељ дархост ба Firestore нест — танҳо ҳисоб. Ба ҳамин сабаб он пурра
 * санҷида мешавад: маҳз дар ҳисоби мӯҳлат ва ҳуқуқ хатогиҳои хомӯш пайдо
 * мешаванд (обунаи гузашта ҳамчун фаъол, ё синни озмоишӣ дубора гирифта шудан).
 */

/** Мӯҳлатҳои дастрас барои гранти соҳиб. */
const GRANT_DURATIONS = {
  '7d': 7 * 24 * 60 * 60 * 1000,
  '30d': 30 * 24 * 60 * 60 * 1000,
  '1y': 365 * 24 * 60 * 60 * 1000,
  lifetime: null, // бе мӯҳлат
};

/** Мӯҳлати синни озмоишӣ — як моҳ. */
const TRIAL_MS = 30 * 24 * 60 * 60 * 1000;

/** Сарчашмаҳои ҳуқуқи Plus. */
const SOURCES = {
  owner: 'owner',
  purchase: 'purchase',
  grant: 'owner_grant',
  trial: 'trial',
};

function isKnownDuration(duration) {
  return Object.prototype.hasOwnProperty.call(GRANT_DURATIONS, duration);
}

/**
 * Мӯҳлати анҷом барои як грант.
 *
 * `null` маънои «бе мӯҳлат» дорад (lifetime) — на «гузашта».
 */
function expiryFor(duration, now = Date.now()) {
  if (!isKnownDuration(duration)) throw new Error(`Мӯҳлати номаълум: ${duration}`);
  const ms = GRANT_DURATIONS[duration];
  return ms === null ? null : now + ms;
}

/**
 * Оё ҳуқуқи Plus ҳозир фаъол аст.
 *
 * Соҳиб ҳамеша фаъол аст ва мӯҳлат надорад. Барои боқимонда:
 * - `active !== true` → нофаъол;
 * - `expiresAt === null` → бе мӯҳлат, фаъол;
 * - вагарна бо вақти ҳозира муқоиса мешавад.
 *
 * Мӯҳлати гузашта ҳатман нофаъол аст, ҳарчанд `active: true` дар ҳуҷҷат монда
 * бошад — ҳуҷҷат худкор нав намешавад ва ба он бовар кардан мумкин нест.
 */
function isActive(plus, { isOwner = false, now = Date.now() } = {}) {
  if (isOwner) return true;
  if (!plus || plus.active !== true) return false;
  const expiresAt = toMillis(plus.expiresAt);
  if (expiresAt === null) return true;
  return expiresAt > now;
}

/** Мӯҳлат метавонад рақам, Date ё Timestamp-и Firestore бошад. */
function toMillis(value) {
  if (value === null || value === undefined) return null;
  if (typeof value === 'number') return value;
  if (value instanceof Date) return value.getTime();
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (typeof value._seconds === 'number') return value._seconds * 1000;
  return null;
}

/**
 * Ҳуҷҷати ҳуқуқ барои гранти соҳиб.
 *
 * `trialUsed` нигоҳ дошта мешавад: грант набояд ба корбар имкони дубора
 * гирифтани синни озмоиширо диҳад.
 */
function grantEntitlement({ duration, ownerUid, previous, now = Date.now() }) {
  return {
    active: true,
    source: SOURCES.grant,
    grantedBy: ownerUid,
    grantedAt: now,
    expiresAt: expiryFor(duration, now),
    trialUsed: previous?.trialUsed === true,
  };
}

/** Ҳуҷҷати ҳуқуқ пас аз бекор кардани соҳиб. */
function revokedEntitlement({ previous }) {
  return {
    active: false,
    source: null,
    grantedBy: null,
    grantedAt: null,
    expiresAt: null,
    // Синни озмоишии истифодашуда бекор карда намешавад.
    trialUsed: previous?.trialUsed === true,
  };
}

/**
 * Ҳуҷҷати ҳуқуқ барои синни озмоишӣ.
 *
 * Агар корбар аллакай синни озмоиширо истифода бурда бошад, `null` бармегардад —
 * ва дархост бояд рад шавад.
 */
function trialEntitlement({ previous, now = Date.now() }) {
  if (previous?.trialUsed === true) return null;
  // Агар Plus аллакай фаъол бошад, синни озмоишӣ маъно надорад ва онро
  // беҳуда сарф кардан хато мебуд.
  if (isActive(previous, { now })) return null;
  return {
    active: true,
    source: SOURCES.trial,
    grantedBy: null,
    grantedAt: now,
    expiresAt: now + TRIAL_MS,
    trialUsed: true,
  };
}

module.exports = {
  GRANT_DURATIONS,
  TRIAL_MS,
  SOURCES,
  isKnownDuration,
  expiryFor,
  isActive,
  toMillis,
  grantEntitlement,
  revokedEntitlement,
  trialEntitlement,
};
