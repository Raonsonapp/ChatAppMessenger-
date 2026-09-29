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

test('uid ҳамеша 0 аст — барои ҳамаи корбарон', () => {
  // Token ба КАНАЛ баста мешавад, на ба корбар.
  //
  // Сабаб амалӣ аст: uid дар token ва uid дар `joinChannel` бояд АЙНАН
  // якхела бошанд, вагарна Agora token-ро рад мекунад ва занг бо хатои
  // «token нодуруст» меафтад. 0 дар ҳар ду ҷо як синфи томи хатогиро —
  // номувофиқатии uid — тамоман барҳам медиҳад.
  //
  // Ҳимоя аз ин суст намешавад: token танҳо ба корбари иҷозатдодашуда
  // дода мешавад (ниг. checkChannelAccess) ва як соат эътибор дорад.
  assert.equal(agora.buildToken('ch', 'firebase-uid-1').uid, 0);
  assert.equal(agora.buildToken('ch', 'firebase-uid-2').uid, 0);
});

test('як канал барои ҳар ду тараф token-и кории якхела медиҳад', () => {
  // Зангзананда ва гиранда бояд ҳар ду ба ҲАМОН канал дароянд.
  const caller = agora.buildToken('call-xyz', 'uid-caller');
  const callee = agora.buildToken('call-xyz', 'uid-callee');
  assert.equal(caller.uid, callee.uid);
  assert.equal(caller.appId, callee.appId);
  assert.match(caller.token, /^007/);
  assert.match(callee.token, /^007/);
});

test('номи канали аз 64 байт дарозтар рад мешавад', () => {
  // Дар барномаи дигари ҳамин муаллиф маҳз ҳамин хатогӣ зангро мешикаст:
  // номи канали 73-аломата хомӯшона рад мешуд ва ҳарду тараф то абад
  // «Пайваст мешавад…» медиданд. Беҳтар аст, ки хатогӣ намоён бошад.
  assert.throws(() => agora.buildToken('x'.repeat(65), 'u1'));
  assert.doesNotThrow(() => agora.buildToken('x'.repeat(64), 'u1'));
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
