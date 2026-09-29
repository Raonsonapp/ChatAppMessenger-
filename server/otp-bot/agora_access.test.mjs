/**
 * Санҷиши дастрасӣ ба канали занг — дар эмулятори ВОҚЕИИ Firestore.
 *
 * Ин ҷо маҳз он чизе санҷида мешавад, ки занги воқеиро мешиканад: агар
 * санҷиш ҳуҷҷати зангро наёбад ё корбарро иштирокчӣ нашуморад, сервер 403
 * бармегардонад ва барнома «хатои token» нишон медиҳад.
 *
 * Иҷро (эмулятор бояд кор кунад):
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8181 node --test agora_access.test.mjs
 */
import assert from 'node:assert/strict';
import test from 'node:test';

process.env.AGORA_APP_ID = 'b3e1bb64096d49528b3449a7bbb0bbc8';
process.env.AGORA_APP_CERTIFICATE = '0123456789abcdef0123456789abcdef';
process.env.GOOGLE_CLOUD_PROJECT = 'demo-chatapp';

const { Firestore } = await import('@google-cloud/firestore');
const agora = await import('./agora.js').then((m) => m.default ?? m);

const db = new Firestore({
  projectId: 'demo-chatapp',
  host: (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8181').split(':')[0],
  port: Number((process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8181').split(':')[1]),
  ssl: false,
});

const A = 'user-a';
const B = 'user-b';
const C = 'user-c';

await db.collection('calls').doc('call-ab').set({
  callerId: A, calleeId: B, participants: [A, B], outcome: 'ringing',
});
await db.collection('groups').doc('grp1').set({
  name: 'G', members: [A, B], admins: [A],
});

test('зангзананда token мегирад', async () => {
  const r = await agora.checkChannelAccess(db, A, 'call-ab');
  assert.equal(r.allowed, true, r.reason);
});

test('гиранда token мегирад', async () => {
  const r = await agora.checkChannelAccess(db, B, 'call-ab');
  assert.equal(r.allowed, true, r.reason);
});

test('шахси бегона ба занги дигарон дохил шуда НАМЕТАВОНАД', async () => {
  // Бе ин санҷиш ҳар корбар метавонист ба сӯҳбати бегона гӯш кунад.
  const r = await agora.checkChannelAccess(db, C, 'call-ab');
  assert.equal(r.allowed, false);
  assert.equal(r.reason, 'not-a-participant');
});

test('канали мавҷуднабуда сабаби аниқ медиҳад', async () => {
  // Маҳз ҳамин ҳолат вақте рӯй медиҳад, ки ҳуҷҷати занг ҳанӯз навишта
  // нашуда, барнома аллакай token мепурсад.
  const r = await agora.checkChannelAccess(db, A, 'call-does-not-exist');
  assert.equal(r.allowed, false);
  assert.equal(r.reason, 'call-not-found');
});

test('узви гурӯҳ ба занги гурӯҳӣ дохил мешавад', async () => {
  const r = await agora.checkChannelAccess(db, B, 'group_grp1_1700000000000');
  assert.equal(r.allowed, true, r.reason);
});

test('ғайриузв ба занги гурӯҳӣ дохил шуда НАМЕТАВОНАД', async () => {
  const r = await agora.checkChannelAccess(db, C, 'group_grp1_1700000000000');
  assert.equal(r.allowed, false);
  assert.equal(r.reason, 'not-a-member');
});

test('гурӯҳи мавҷуднабуда сабаби аниқ медиҳад', async () => {
  const r = await agora.checkChannelAccess(db, A, 'group_nope_1700000000000');
  assert.equal(r.allowed, false);
  assert.equal(r.reason, 'group-not-found');
});

test('номи канали занги воқеӣ аз 64 байт кӯтоҳтар аст', () => {
  // Маҳз ҳамин хатогӣ дар барномаи дигар зангро мешикаст: номи 73-аломата
  // хомӯшона рад мешуд ва ҳарду тараф то абад «Пайваст мешавад…» медиданд.
  const callChannel = 'aBcDeFgHiJkLmNoPqRsT'; // id-и Firestore — 20 аломат
  const groupChannel = `group_${'g'.repeat(20)}_${Date.now()}`;

  assert.ok(Buffer.byteLength(callChannel) <= agora.MAX_CHANNEL_BYTES);
  assert.ok(Buffer.byteLength(groupChannel) <= agora.MAX_CHANNEL_BYTES,
    `дарозӣ=${Buffer.byteLength(groupChannel)}`);
});

test('номи хеле дароз рад карда мешавад, на хомӯшона қабул', () => {
  assert.throws(() => agora.buildToken('x'.repeat(65), A));
});
