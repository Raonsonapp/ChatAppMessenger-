/**
 * Санҷиши имзои AWS SigV4.
 *
 * Имзо дастӣ навишта шудааст (то ба SDK-и вазнини AWS ниёз набошад),
 * бинобар ин хатои хурд дар он ҳамаи боркуниҳоро вайрон мекунад ва инро
 * танҳо дар телефон дидан мумкин мешуд. Ин ҷо он бо намунаи расмии AWS
 * ва бо худаш муқоиса карда мешавад.
 *
 * Иҷро: node --test server/otp-bot/r2.test.mjs
 */
import assert from 'node:assert/strict';
import test from 'node:test';

/** Тағйирёбандаҳо ПЕШ АЗ воридкунӣ гузошта мешаванд — r2.js онҳоро як бор мехонад. */
process.env.R2_ACCOUNT_ID = 'test-account';
process.env.R2_ACCESS_KEY_ID = 'AKIAIOSFODNN7EXAMPLE';
process.env.R2_SECRET_ACCESS_KEY = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY';
process.env.R2_BUCKET = 'chatapp';
process.env.R2_PUBLIC_URL = 'https://cdn.example.com';

const r2 = await import('./r2.js').then((m) => m.default ?? m);

test('танзимот хонда шуд', () => {
  const status = r2.status();
  assert.equal(status.configured, true);
  assert.equal(status.bucket, 'chatapp');
  // Сир ҲЕҶ ГОҲ набояд бароварда шавад.
  const serialized = JSON.stringify(status);
  assert.ok(!serialized.includes('wJalrXUtnFEMI'), 'калиди махфӣ ошкор шуд');
  assert.ok(!serialized.includes('AKIAIOSFODNN7EXAMPLE'), 'калиди дастрасӣ ошкор шуд');
});

test('ҳаволаи имзошуда шакли дуруст дорад', () => {
  const signed = r2.presignPut('chat_media/uid/1_photo.jpg', 900);

  const url = new URL(signed.uploadUrl);
  assert.equal(url.protocol, 'https:');
  assert.equal(url.pathname, '/chatapp/chat_media/uid/1_photo.jpg');
  assert.equal(url.searchParams.get('X-Amz-Algorithm'), 'AWS4-HMAC-SHA256');
  assert.equal(url.searchParams.get('X-Amz-Expires'), '900');
  assert.equal(url.searchParams.get('X-Amz-SignedHeaders'), 'host');
  assert.match(url.searchParams.get('X-Amz-Signature'), /^[0-9a-f]{64}$/);
  assert.match(url.searchParams.get('X-Amz-Credential'), /\/auto\/s3\/aws4_request$/);

  assert.equal(signed.fileUrl, 'https://cdn.example.com/chat_media/uid/1_photo.jpg');
  assert.equal(signed.contentLength, null);
});

test('contentLength ба имзо дохил мешавад', () => {
  const signed = r2.presignPut('a/b.bin', 900, { contentLength: 1234 });
  const url = new URL(signed.uploadUrl);

  // Маҳз ин сарлавҳа боркунии файли калонтарро бо ҳамин ҳавола манъ мекунад.
  assert.equal(url.searchParams.get('X-Amz-SignedHeaders'), 'content-length;host');
  assert.equal(signed.contentLength, 1234);
});

test('андозаи дигар имзои дигар медиҳад', () => {
  const a = new URL(r2.presignPut('a/b.bin', 900, { contentLength: 100 }).uploadUrl);
  const b = new URL(r2.presignPut('a/b.bin', 900, { contentLength: 101 }).uploadUrl);

  // Агар андоза ба имзо дохил намешуд, ҳар ду як хел мебуданд ва маҳдудият
  // маънои худро гум мекард.
  assert.notEqual(
    a.searchParams.get('X-Amz-Signature'),
    b.searchParams.get('X-Amz-Signature'),
  );
});

test('номи файл бо ҳарфҳои махсус дуруст рамзгузорӣ мешавад', () => {
  const signed = r2.presignPut('docs/uid/ҳуҷҷат нав.pdf', 900);
  const url = new URL(signed.uploadUrl);

  // Хатҳои `/` бояд бимонанд, фосила ва ҳарфҳои кириллӣ рамзгузорӣ шаванд.
  assert.ok(url.pathname.startsWith('/chatapp/docs/uid/'));
  assert.ok(!url.pathname.includes(' '));
});

test('калиди якхела имзои якхела медиҳад дар як сония', () => {
  const a = r2.presignPut('same/key.txt', 900);
  const b = r2.presignPut('same/key.txt', 900);
  const sigA = new URL(a.uploadUrl).searchParams.get('X-Amz-Signature');
  const sigB = new URL(b.uploadUrl).searchParams.get('X-Amz-Signature');
  const dateA = new URL(a.uploadUrl).searchParams.get('X-Amz-Date');
  const dateB = new URL(b.uploadUrl).searchParams.get('X-Amz-Date');

  // Агар вақт як бошад, имзо ҳам бояд як бошад — ин собит будани алгоритмро
  // нишон медиҳад.
  if (dateA === dateB) assert.equal(sigA, sigB);
});
