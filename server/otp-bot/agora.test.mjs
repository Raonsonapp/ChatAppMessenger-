/**
 * Санҷиши token-и Agora.
 *
 * Иҷро: node --test server/otp-bot/agora.test.mjs
 */
import assert from 'node:assert/strict';
import test from 'node:test';

process.env.AGORA_APP_ID = 'b3e1bb64096d49528b3449a7bbb0bbc8';
process.env.AGORA_APP_CERTIFICATE = '0123456789abcdef0123456789abcdef';

const agora = await import('./agora.js').then((m) => m.default ?? m);

test('танзимот хонда шуд', () => {
  const status = agora.status();
  assert.equal(status.mode, 'token');
  assert.equal(status.hasAppId, true);
  assert.equal(status.hasCertificate, true);
});

test('Certificate ҲЕҶ ГОҲ ошкор намешавад', () => {
  // App ID сир нест, вале Certificate калиди махфист: агар он ба барнома
  // расад, ҳар кас метавонад бо ҳисоби мо занг занад.
  const serialized = JSON.stringify(agora.status());
  assert.ok(!serialized.includes('0123456789abcdef'), 'Certificate ошкор шуд');
});

test('token сохта мешавад ва шакли AccessToken2 дорад', () => {
  const built = agora.buildToken('call-abc', 'firebase-uid-1');
  // «007» — версияи AccessToken2.
  assert.match(built.token, /^007/);
  assert.equal(built.appId, process.env.AGORA_APP_ID);
  assert.ok(built.expiresInSeconds > 0);
});

test('uid устувор аст', () => {
  // Агар uid ҳар бор тағйир ёбад, token ба корбари дигар баста мешавад ва
  // ҳамроҳ шудан ноком мегардад.
  const a = agora.buildToken('ch', 'firebase-uid-1').uid;
  const b = agora.buildToken('ch', 'firebase-uid-1').uid;
  assert.equal(a, b);
});

test('корбарони гуногун uid-и гуногун доранд', () => {
  const a = agora.buildToken('ch', 'firebase-uid-1').uid;
  const b = agora.buildToken('ch', 'firebase-uid-2').uid;
  assert.notEqual(a, b);
});

test('uid ҳељ гоҳ сифр нест ва дар доираи int32 аст', () => {
  // Дар Agora uid=0 маънои «ҳар корбар»-ро дорад — яъне token ҳимояи худро
  // гум мекунад.
  for (let i = 0; i < 200; i++) {
    const uid = agora.numericUid(`user-${i}`);
    assert.ok(uid > 0, `uid=${uid}`);
    assert.ok(uid <= 0x7fffffff, `uid=${uid}`);
  }
});

test('канали дигар token-и дигар медиҳад', () => {
  const a = agora.buildToken('channel-a', 'u1').token;
  const b = agora.buildToken('channel-b', 'u1').token;
  // Вагарна token-и як занг барои даромадан ба занги дигар кор мекард.
  assert.notEqual(a, b);
});

test('id-и гурӯҳ аз номи канал ҷудо мешавад', () => {
  assert.equal(agora.groupIdFromChannel('group_abc123_1700000000'), 'abc123');
  // Id-и дорои хати поёнӣ низ дуруст ҷудо мешавад.
  assert.equal(agora.groupIdFromChannel('group_a_b_c_1700000000'), 'a_b_c');
  // Канали занги шахсӣ гурӯҳ нест.
  assert.equal(agora.groupIdFromChannel('AbCdEf123456'), null);
  assert.equal(agora.groupIdFromChannel('group_noTimestamp'), null);
});
