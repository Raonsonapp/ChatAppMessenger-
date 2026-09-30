import assert from 'node:assert';
import { test } from 'node:test';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { deviceFingerprint } = require('./device_fingerprint.js');

// Ин қиматҳо ҳамонҳоеанд ки `test/device_service_test.dart` талаб мекунад.
// Агар як тараф тағйир ёбад, дигараш дарҳол меафтад — ва маҳз ҳамин лозим аст:
// ҳар ду тараф бояд ҳамон ID-и ҳуҷҷати дастгоҳро ҳисоб кунанд.
test('асоси FNV-1a барои сатри холӣ', () => {
  assert.equal(deviceFingerprint(''), 'cbf29ce484222325');
});

test('дарозӣ ҳамеша 16 рақами шонздаҳӣ', () => {
  for (const token of ['a', 'fZ9k:APA91bH', 'APA91bH'.repeat(30)]) {
    const id = deviceFingerprint(token);
    assert.equal(id.length, 16, token);
    assert.match(id, /^[0-9a-f]{16}$/);
  }
});

test('токенҳои гуногун ID-и гуногун медиҳанд', () => {
  assert.notEqual(deviceFingerprint('token-a'), deviceFingerprint('token-b'));
});

test('ҳамон токен ҳамон ID медиҳад', () => {
  const token = 'fZ9k:APA91bHqExampleToken_1234567890';
  assert.equal(deviceFingerprint(token), deviceFingerprint(token));
});

test('ID токенро ошкор намекунад', () => {
  const token = 'secret-fcm-token-value';
  const id = deviceFingerprint(token);
  assert.ok(!id.includes('secret'));
  assert.ok(!token.includes(id));
});
