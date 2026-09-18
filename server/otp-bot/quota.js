'use strict';

/**
 * Маҳдудияти амалҳо барои як корбар дар як соат.
 *
 * Ҳисоб дар хотира нигоҳ дошта мешавад: барои як нусхаи сервер ин кофӣ аст
 * ва ба махзани беруна ниёз надорад. Пас аз аз нав оғоз шудани сервер ҳисоб
 * сифр мешавад — ин ҳадди ниҳоӣ нест, балки ҳимоя аз суиистифодаи оддист.
 */

const HOUR_MS = 60 * 60 * 1000;

/** Пас аз ин шумораи корбарон сабтҳои кӯҳна тоза карда мешаванд. */
const CLEANUP_THRESHOLD = 5000;

/**
 * Арзиши амалро ба ҳисоби корбар илова мекунад.
 *
 * @param {Map<string, {since: number, count: number}>} bucket ҷои нигоҳдорӣ
 * @param {string} uid корбар
 * @param {number} limit ҳадди ниҳоӣ дар як соат
 * @param {number} cost арзиши ин амал (масалан шумораи гирандагон)
 * @param {number} now вақти ҷорӣ — барои санҷиш дода мешавад
 * @returns {boolean} `true` — агар ҳад гузашта бошад
 */
function overQuota(bucket, uid, limit, cost = 1, now = Date.now()) {
  const entry = bucket.get(uid);

  if (!entry || now - entry.since > HOUR_MS) {
    bucket.set(uid, { since: now, count: cost });

    if (bucket.size > CLEANUP_THRESHOLD) {
      for (const [key, value] of bucket) {
        if (now - value.since > HOUR_MS) bucket.delete(key);
      }
    }
    return cost > limit;
  }

  entry.count += cost;
  return entry.count > limit;
}

module.exports = { overQuota, HOUR_MS };
