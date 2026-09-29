'use strict';

const crypto = require('node:crypto');
const dns = require('node:dns').promises;
const net = require('node:net');

/**
 * Пешнамоиши ҳавола — сарлавҳа, тавсиф ва акс.
 *
 * Дархостро СЕРВЕР мефиристад, на барнома. Ду сабаб:
 * 1. Натиҷа кэш карда мешавад — як ҳавола дар гурӯҳи 200-нафара 200 бор
 *    кашида намешавад.
 * 2. Барнома IP-и корбарро ба сайти бегона намедиҳад.
 */

/** Ҳаҷми ҳадди ҷавоб — сарлавҳа дар аввали саҳифа аст. */
const MAX_BYTES = 512 * 1024;
const TIMEOUT_MS = 8000;

/**
 * Ҳимоя аз SSRF.
 *
 * Бе ин касе метавонист ба сервер фармояд, ки ба шабакаи дохилӣ муроҷиат
 * кунад (масалан ба хидмати метамаълумоти абрӣ) ва натиҷаро бихонад.
 */
function isPrivateAddress(address) {
  if (net.isIPv4(address)) {
    const [a, b] = address.split('.').map(Number);
    if (a === 10 || a === 127 || a === 0) return true;
    if (a === 172 && b >= 16 && b <= 31) return true;
    if (a === 192 && b === 168) return true;
    if (a === 169 && b === 254) return true; // метамаълумоти абрӣ
    if (a >= 224) return true; // multicast ва захирашуда
    return false;
  }
  if (net.isIPv6(address)) {
    const lower = address.toLowerCase();
    if (lower === '::1' || lower === '::') return true;
    if (lower.startsWith('fc') || lower.startsWith('fd')) return true; // маҳаллӣ
    if (lower.startsWith('fe80')) return true; // link-local
    // IPv4 дар қолаби IPv6.
    const mapped = lower.match(/::ffff:(\d+\.\d+\.\d+\.\d+)/);
    if (mapped) return isPrivateAddress(mapped[1]);
    return false;
  }
  return true;
}

async function assertPublicHost(hostname) {
  // Агар худи ном IP бошад, онро бевосита месанҷем.
  if (net.isIP(hostname)) {
    if (isPrivateAddress(hostname)) throw new Error('private-address');
    return;
  }
  const records = await dns.lookup(hostname, { all: true });
  if (records.length === 0) throw new Error('dns-failed');
  for (const record of records) {
    if (isPrivateAddress(record.address)) throw new Error('private-address');
  }
}

/** Калиди кэш — худи ҳавола дар id-и ҳуҷҷат ҷой намешавад. */
function cacheKey(url) {
  return crypto.createHash('sha256').update(url).digest('hex').slice(0, 32);
}

function decodeEntities(text) {
  return text
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#(\d+);/g, (_, code) => String.fromCharCode(Number(code)))
    .replace(/&#x([0-9a-f]+);/gi, (_, code) => String.fromCharCode(parseInt(code, 16)))
    .replace(/&apos;/g, "'")
    .replace(/&nbsp;/g, ' ');
}

/** Қимати мета-теги `property` ё `name`. */
function metaContent(html, names) {
  for (const name of names) {
    const pattern = new RegExp(
      `<meta[^>]+(?:property|name)\\s*=\\s*["']${name}["'][^>]*>`,
      'i',
    );
    const tag = html.match(pattern)?.[0];
    if (!tag) continue;
    const content = tag.match(/content\s*=\s*["']([^"']*)["']/i)?.[1];
    if (content && content.trim()) return decodeEntities(content.trim());
  }
  return null;
}

function parse(html, finalUrl) {
  const title =
    metaContent(html, ['og:title', 'twitter:title']) ||
    (html.match(/<title[^>]*>([\s\S]*?)<\/title>/i)?.[1]?.trim()
      ? decodeEntities(html.match(/<title[^>]*>([\s\S]*?)<\/title>/i)[1].trim())
      : null);

  const description = metaContent(html, [
    'og:description',
    'twitter:description',
    'description',
  ]);

  let image = metaContent(html, ['og:image', 'og:image:url', 'twitter:image']);
  if (image) {
    try {
      // Ҳаволаи нисбӣ ба мутлақ табдил дода мешавад.
      image = new URL(image, finalUrl).toString();
    } catch {
      image = null;
    }
  }

  let siteName = metaContent(html, ['og:site_name']);
  if (!siteName) {
    try {
      siteName = new URL(finalUrl).hostname.replace(/^www\./, '');
    } catch {
      siteName = null;
    }
  }

  return { url: finalUrl, title, description, image, siteName };
}

/**
 * Пешнамоишро мекашад. `null` — агар чизи муфид ёфт нашавад.
 */
async function fetchPreview(rawUrl) {
  let url;
  try {
    url = new URL(rawUrl);
  } catch {
    throw new Error('bad-url');
  }
  if (url.protocol !== 'http:' && url.protocol !== 'https:') {
    throw new Error('bad-protocol');
  }

  await assertPublicHost(url.hostname);

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);

  let response;
  try {
    response = await fetch(url.toString(), {
      signal: controller.signal,
      redirect: 'follow',
      headers: {
        // Баъзе сайтҳо бе ин мета-тегҳоро намедиҳанд.
        'User-Agent': 'Mozilla/5.0 (compatible; ChatAppBot/1.0)',
        Accept: 'text/html,application/xhtml+xml',
      },
    });
  } finally {
    clearTimeout(timer);
  }

  if (!response.ok) throw new Error(`http-${response.status}`);

  // Пас аз гузаришҳо суроға метавонад тағйир ёбад — онро низ месанҷем.
  const finalUrl = response.url || url.toString();
  try {
    await assertPublicHost(new URL(finalUrl).hostname);
  } catch {
    throw new Error('private-address');
  }

  const type = response.headers.get('content-type') || '';
  if (!type.includes('html')) throw new Error('not-html');

  // Танҳо оғози саҳифа хонда мешавад: мета-тегҳо дар `<head>` мебошанд ва
  // саҳифаи чандмегабайтро пурра кашидан беҳуда аст.
  const reader = response.body?.getReader();
  if (!reader) throw new Error('no-body');

  const chunks = [];
  let total = 0;
  while (total < MAX_BYTES) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(value);
    total += value.length;
  }
  try {
    await reader.cancel();
  } catch {}

  const html = Buffer.concat(chunks.map(Buffer.from)).toString('utf8');
  const preview = parse(html, finalUrl);
  if (!preview.title && !preview.description && !preview.image) return null;
  return preview;
}

module.exports = { fetchPreview, cacheKey, isPrivateAddress, parse };
