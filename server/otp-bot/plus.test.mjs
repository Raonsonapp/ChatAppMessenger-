import assert from 'node:assert';
import { test } from 'node:test';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const plus = require('./plus.js');

const NOW = 1_700_000_000_000;
const DAY = 24 * 60 * 60 * 1000;

test('мӯҳлатҳои маълум ва номаълум', () => {
  assert.ok(plus.isKnownDuration('7d'));
  assert.ok(plus.isKnownDuration('30d'));
  assert.ok(plus.isKnownDuration('1y'));
  assert.ok(plus.isKnownDuration('lifetime'));
  assert.ok(!plus.isKnownDuration('forever'));
  assert.ok(!plus.isKnownDuration(''));
  // Майдонҳои меросии Object набояд ҳамчун мӯҳлат қабул шаванд.
  assert.ok(!plus.isKnownDuration('constructor'));
  assert.ok(!plus.isKnownDuration('toString'));
});

test('lifetime мӯҳлат надорад, на мӯҳлати гузашта', () => {
  assert.equal(plus.expiryFor('lifetime', NOW), null);
});

test('7d ва 1y дуруст ҳисоб мешаванд', () => {
  assert.equal(plus.expiryFor('7d', NOW), NOW + 7 * DAY);
  assert.equal(plus.expiryFor('1y', NOW), NOW + 365 * DAY);
});

test('мӯҳлати номаълум истисно мепартояд', () => {
  assert.throws(() => plus.expiryFor('10y', NOW));
});

test('соҳиб ҳамеша фаъол аст, ҳатто бе ҳуҷҷат', () => {
  assert.ok(plus.isActive(null, { isOwner: true, now: NOW }));
  assert.ok(plus.isActive({ active: false }, { isOwner: true, now: NOW }));
});

test('бе ҳуҷҷат ва бе active фаъол нест', () => {
  assert.ok(!plus.isActive(null, { now: NOW }));
  assert.ok(!plus.isActive({}, { now: NOW }));
  assert.ok(!plus.isActive({ active: false, expiresAt: null }, { now: NOW }));
  // `active: 'true'` сатр аст, на bool — набояд қабул шавад.
  assert.ok(!plus.isActive({ active: 'true', expiresAt: null }, { now: NOW }));
});

test('expiresAt null — бе мӯҳлат, фаъол', () => {
  assert.ok(plus.isActive({ active: true, expiresAt: null }, { now: NOW }));
});

test('мӯҳлати гузашта фаъол нест, ҳарчанд active: true бошад', () => {
  // Ҳуҷҷат худкор нав намешавад — ба `active` бовар кардан мумкин нест.
  assert.ok(!plus.isActive({ active: true, expiresAt: NOW - 1 }, { now: NOW }));
  assert.ok(!plus.isActive({ active: true, expiresAt: NOW }, { now: NOW }));
  assert.ok(plus.isActive({ active: true, expiresAt: NOW + 1 }, { now: NOW }));
});

test('Timestamp-и Firestore ва Date хонда мешаванд', () => {
  const stamp = { toMillis: () => NOW + DAY };
  assert.ok(plus.isActive({ active: true, expiresAt: stamp }, { now: NOW }));
  assert.ok(plus.isActive({ active: true, expiresAt: new Date(NOW + DAY) }, { now: NOW }));
  assert.ok(!plus.isActive({ active: true, expiresAt: new Date(NOW - DAY) }, { now: NOW }));
  assert.equal(plus.toMillis({ _seconds: 1700 }), 1_700_000);
});

test('гранти соҳиб ҳуҷҷати дуруст медиҳад', () => {
  const entitlement = plus.grantEntitlement({
    duration: '30d',
    ownerUid: 'owner1',
    previous: null,
    now: NOW,
  });
  assert.equal(entitlement.active, true);
  assert.equal(entitlement.source, 'owner_grant');
  assert.equal(entitlement.grantedBy, 'owner1');
  assert.equal(entitlement.expiresAt, NOW + 30 * DAY);
  assert.equal(entitlement.trialUsed, false);
});

test('грант синни озмоишии истифодашударо аз нав намекушояд', () => {
  const entitlement = plus.grantEntitlement({
    duration: 'lifetime',
    ownerUid: 'owner1',
    previous: { trialUsed: true },
    now: NOW,
  });
  assert.equal(entitlement.trialUsed, true);
  assert.equal(entitlement.expiresAt, null);
});

test('бекор кардан синни озмоиширо барнамегардонад', () => {
  const entitlement = plus.revokedEntitlement({ previous: { trialUsed: true } });
  assert.equal(entitlement.active, false);
  assert.equal(entitlement.trialUsed, true);
  assert.ok(!plus.isActive(entitlement, { now: NOW }));
});

test('синни озмоишӣ як маротиба дода мешавад', () => {
  const first = plus.trialEntitlement({ previous: null, now: NOW });
  assert.ok(first);
  assert.equal(first.source, 'trial');
  assert.equal(first.trialUsed, true);
  assert.equal(first.expiresAt, NOW + plus.TRIAL_MS);

  // Дубора — рад мешавад.
  assert.equal(plus.trialEntitlement({ previous: first, now: NOW }), null);
});

test('синни озмоишӣ ҳангоми Plus-и фаъол дода намешавад', () => {
  // Вагарна корбар моҳи муфти худро беҳуда сарф мекунад.
  const active = { active: true, expiresAt: NOW + 365 * DAY, trialUsed: false };
  assert.equal(plus.trialEntitlement({ previous: active, now: NOW }), null);
});

test('синни озмоишии гузашта дубора дода намешавад', () => {
  const expired = { active: true, expiresAt: NOW - DAY, trialUsed: true };
  assert.equal(plus.trialEntitlement({ previous: expired, now: NOW }), null);
});
