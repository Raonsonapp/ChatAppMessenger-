/**
 * Санҷиши пешнамоиши ҳавола.
 *
 * Муҳимтарин қисм — ҳимоя аз SSRF: бе он касе метавонист ба сервер
 * фармояд, ки ба шабакаи дохилӣ муроҷиат кунад ва натиҷаро бихонад.
 */
import assert from 'node:assert/strict';
import test from 'node:test';

const lp = await import('./link_preview.js').then((m) => m.default ?? m);

test('суроғаҳои дохилӣ манъ мешаванд', () => {
  const blocked = [
    '127.0.0.1', '10.0.0.5', '172.16.3.1', '172.31.255.255',
    '192.168.1.1', '169.254.169.254', // метамаълумоти абрӣ
    '0.0.0.0', '::1', 'fd00::1', 'fe80::1', '::ffff:127.0.0.1',
  ];
  for (const address of blocked) {
    assert.equal(lp.isPrivateAddress(address), true, address);
  }
});

test('суроғаҳои ҷамъиятӣ иҷозат доранд', () => {
  for (const address of ['8.8.8.8', '1.1.1.1', '93.184.216.34', '2606:4700::1']) {
    assert.equal(lp.isPrivateAddress(address), false, address);
  }
});

test('172.15 ва 172.32 дохилӣ НЕСТАНД', () => {
  // Маҳдудаи хусусӣ танҳо 172.16–172.31 аст; хатои маъмул тамоми 172-ро
  // манъ кардан ё умуман манъ накардан аст.
  assert.equal(lp.isPrivateAddress('172.15.0.1'), false);
  assert.equal(lp.isPrivateAddress('172.32.0.1'), false);
  assert.equal(lp.isPrivateAddress('172.16.0.1'), true);
  assert.equal(lp.isPrivateAddress('172.31.0.1'), true);
});

test('мета-тегҳои Open Graph хонда мешаванд', () => {
  const html = `<html><head>
    <meta property="og:title" content="Сарлавҳа" />
    <meta property="og:description" content="Тавсиф" />
    <meta property="og:image" content="/pic.png" />
    <meta property="og:site_name" content="Мисол" />
  </head></html>`;
  const p = lp.parse(html, 'https://example.com/page');
  assert.equal(p.title, 'Сарлавҳа');
  assert.equal(p.description, 'Тавсиф');
  // Ҳаволаи нисбӣ бояд мутлақ шавад, вагарна акс кушода намешавад.
  assert.equal(p.image, 'https://example.com/pic.png');
  assert.equal(p.siteName, 'Мисол');
});

test('агар og:title набошад, <title> гирифта мешавад', () => {
  const p = lp.parse('<html><head><title>Оддӣ</title></head></html>', 'https://a.example/x');
  assert.equal(p.title, 'Оддӣ');
  assert.equal(p.siteName, 'a.example');
});

test('аломатҳои HTML кушода мешаванд', () => {
  const html = '<html><head><title>Чой &amp; Нон &#8212; хуб</title></head></html>';
  const p = lp.parse(html, 'https://x.example/');
  assert.ok(p.title.includes('&'));
  assert.ok(!p.title.includes('&amp;'));
});

test('калиди кэш устувор ва бе худи ҳавола аст', () => {
  const a = lp.cacheKey('https://example.com/a');
  const b = lp.cacheKey('https://example.com/a');
  const c = lp.cacheKey('https://example.com/b');
  assert.equal(a, b);
  assert.notEqual(a, c);
  assert.match(a, /^[0-9a-f]{32}$/);
});

test('ҳаволаи нодуруст ва протоколи бегона рад мешаванд', async () => {
  await assert.rejects(() => lp.fetchPreview('not a url'));
  // `file:` ва `gopher:` набояд кушода шаванд.
  await assert.rejects(() => lp.fetchPreview('file:///etc/passwd'));
});

test('ҳаволаи ба шабакаи дохилӣ ишоракунанда рад мешавад', async () => {
  await assert.rejects(
    () => lp.fetchPreview('http://169.254.169.254/latest/meta-data/'),
    /private-address/,
  );
  await assert.rejects(() => lp.fetchPreview('http://127.0.0.1:8080/'), /private-address/);
});
