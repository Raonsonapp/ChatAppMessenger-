/**
 * Санҷиши маҳдудияти амалҳо.
 *
 * Иҷро: node --test server/otp-bot/quota.test.mjs
 */
import assert from 'node:assert/strict';
import test from 'node:test';

import quota from './quota.js';

const { overQuota, HOUR_MS } = quota;

test('то ҳад иҷозат дода мешавад', () => {
  const bucket = new Map();
  for (let i = 0; i < 5; i++) {
    assert.equal(overQuota(bucket, 'u1', 5), false, `қадами ${i + 1}`);
  }
});

test('пас аз ҳад манъ мешавад', () => {
  const bucket = new Map();
  for (let i = 0; i < 5; i++) overQuota(bucket, 'u1', 5);
  assert.equal(overQuota(bucket, 'u1', 5), true);
});

test('корбарони гуногун ҳисоби ҷудогона доранд', () => {
  const bucket = new Map();
  for (let i = 0; i < 6; i++) overQuota(bucket, 'u1', 5);
  // Ҳисоби u1 пур шуд, вале ин набояд ба u2 таъсир кунад.
  assert.equal(overQuota(bucket, 'u2', 5), false);
});

test('пас аз як соат ҳисоб сифр мешавад', () => {
  const bucket = new Map();
  const start = 1_000_000;
  for (let i = 0; i < 6; i++) overQuota(bucket, 'u1', 5, 1, start);
  assert.equal(overQuota(bucket, 'u1', 5, 1, start), true);

  // Як соату як дақиқа баъд.
  assert.equal(overQuota(bucket, 'u1', 5, 1, start + HOUR_MS + 60_000), false);
});

test('арзиш ба назар гирифта мешавад', () => {
  const bucket = new Map();
  // Як амали гарон (масалан огоҳинома ба 100 нафар) бояд ҳамон қадар ҳисоб
  // шавад — вагарна маҳдудиятро бо як дархости калон давр задан мумкин аст.
  assert.equal(overQuota(bucket, 'u1', 150, 100), false);
  assert.equal(overQuota(bucket, 'u1', 150, 100), true);
});

test('як амали хеле гарон фавран манъ мешавад', () => {
  const bucket = new Map();
  // Ҳатто аввалин амал, агар аз ҳад гузарад, бояд манъ шавад.
  assert.equal(overQuota(bucket, 'u1', 50, 500), true);
});
