'use strict';

const crypto = require('node:crypto');

/**
 * Cloudflare R2 — анбори файлҳои барнома (расм, видео, овоз, ҳуҷҷат).
 *
 * Калидҳои R2 ҲЕҶ ГОҲ ба барнома дода намешаванд: онҳоро аз APK кашида
 * гирифтан мумкин аст. Ба ҷои он сервер ҳаволаи имзошудаи кӯтоҳмуддат
 * (presigned URL) месозад ва барнома файлро бевосита ба R2 мефиристад.
 *
 * R2 бо S3 мувофиқ аст, бинобар ин имзои AWS SigV4 истифода мешавад. Он дар
 * ин ҷо дастӣ навишта шуд, то ба SDK-и вазнини AWS ниёз набошад.
 */

/** Якчанд номи маъмули тағйирёбандаҳо дастгирӣ мешавад. */
function pick(...names) {
  for (const name of names) {
    const value = process.env[name];
    if (value && String(value).trim()) return String(value).trim();
  }
  return null;
}

const config = {
  accountId: pick('R2_ACCOUNT_ID', 'CLOUDFLARE_ACCOUNT_ID', 'CF_ACCOUNT_ID'),
  accessKeyId: pick(
    'R2_ACCESS_KEY_ID',
    'R2_ACCESS_KEY',
    'R2_KEY_ID',
    'R2_TOKEN_ID',
    'CF_R2_ACCESS_KEY_ID',
    'CF_R2_ACCESS_KEY',
    'CF_ACCESS_KEY_ID',
    'CLOUDFLARE_R2_ACCESS_KEY_ID',
    'CLOUDFLARE_ACCESS_KEY_ID',
    'AWS_ACCESS_KEY_ID',
    'S3_ACCESS_KEY_ID',
    'ACCESS_KEY_ID',
  ),
  secretAccessKey: pick(
    'R2_SECRET_ACCESS_KEY',
    'R2_SECRET_KEY',
    'R2_SECRET',
    'R2_TOKEN',
    'CF_R2_SECRET_ACCESS_KEY',
    'CF_R2_SECRET_KEY',
    'CF_SECRET_ACCESS_KEY',
    'CLOUDFLARE_R2_SECRET_ACCESS_KEY',
    'CLOUDFLARE_SECRET_ACCESS_KEY',
    'AWS_SECRET_ACCESS_KEY',
    'S3_SECRET_ACCESS_KEY',
    'SECRET_ACCESS_KEY',
  ),
  bucket: pick(
    'R2_BUCKET',
    'R2_BUCKET_NAME',
    'CF_R2_BUCKET',
    'CF_R2_BUCKET_NAME',
    'CF_BUCKET',
    'CLOUDFLARE_R2_BUCKET',
    'S3_BUCKET',
    'BUCKET_NAME',
    'BUCKET',
  ),
  // Суроғаи ҷамъиятии бакет: домени r2.dev ё домени худӣ.
  publicUrl: pick(
    'R2_PUBLIC_URL',
    'CF_R2_PUBLIC_URL',
    'CF_PUBLIC_URL',
    'R2_PUBLIC_BASE_URL',
    'R2_DOMAIN',
    'R2_PUBLIC_DOMAIN',
    'R2_DEV_URL',
    'PUBLIC_BUCKET_URL',
    'CDN_URL',
  ),
  // Агар домени endpoint-и махсус дода шуда бошад (вагарна аз accountId сохта мешавад).
  endpoint: pick('R2_ENDPOINT', 'R2_S3_ENDPOINT'),
};

/** Endpoint метавонад бо роҳи бакет дода шавад — онро ҷудо мекунем. */
function splitEndpoint() {
  if (!config.endpoint) return { host: null, bucket: null };
  const withoutScheme = config.endpoint.replace(/^https?:\/\//, '').replace(/\/+$/, '');
  const slash = withoutScheme.indexOf('/');
  if (slash === -1) return { host: withoutScheme, bucket: null };
  return {
    host: withoutScheme.slice(0, slash),
    bucket: withoutScheme.slice(slash + 1) || null,
  };
}

function endpointHost() {
  const fromEndpoint = splitEndpoint().host;
  if (fromEndpoint) return fromEndpoint;
  return `${config.accountId}.r2.cloudflarestorage.com`;
}

/** Номи бакет: аз тағйирёбанда ё аз роҳи endpoint. */
function bucketName() {
  return config.bucket || splitEndpoint().bucket;
}

function publicBase() {
  if (!config.publicUrl) return null;
  const withScheme = /^https?:\/\//.test(config.publicUrl)
    ? config.publicUrl
    : `https://${config.publicUrl}`;
  return withScheme.replace(/\/+$/, '');
}

/** Оё R2 пурра танзим шудааст. */
function isConfigured() {
  return Boolean(config.accountId || config.endpoint)
    && Boolean(config.accessKeyId)
    && Boolean(config.secretAccessKey)
    && Boolean(bucketName());
}

/**
 * Номҳои тағйирёбандаҳои ба R2 монанд, ки дар муҳит ҳастанд.
 *
 * ТАНҲО НОМҲО бармегарданд — ҳељ гоҳ худи қиматҳо. Ин барои он аст, ки агар
 * калид бо номи дигар гузошта шуда бошад, онро дидан ва ислоҳ кардан мумкин
 * бошад, бе он ки сир ошкор шавад.
 */
function seenVariableNames() {
  return Object.keys(process.env)
    .filter((name) => /R2|CLOUDFLARE|^CF_|S3|BUCKET|ACCESS_KEY|SECRET|ENDPOINT/i.test(name))
    .sort();
}

/** Барои саҳифаи ташхис — бе ҳељ сирре. */
function status() {
  return {
    seenVariableNames: seenVariableNames(),
    configured: isConfigured(),
    hasAccount: Boolean(config.accountId || config.endpoint),
    hasAccessKey: Boolean(config.accessKeyId),
    hasSecretKey: Boolean(config.secretAccessKey),
    hasBucket: Boolean(bucketName()),
    hasPublicUrl: Boolean(config.publicUrl),
    bucket: bucketName(),
    endpoint: isConfigured() ? endpointHost() : null,
    publicUrl: publicBase(),
  };
}

const UNSIGNED_PAYLOAD = 'UNSIGNED-PAYLOAD';

function sha256Hex(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function hmac(key, value) {
  return crypto.createHmac('sha256', key).update(value).digest();
}

/** Ҳар сегменти роҳ алоҳида рамзгузорӣ мешавад — `/` бояд боқӣ монад. */
function encodePath(key) {
  return key
    .split('/')
    .map((segment) => encodeURIComponent(segment).replace(/[!'()*]/g, (c) =>
      `%${c.charCodeAt(0).toString(16).toUpperCase()}`))
    .join('/');
}

/**
 * Ҳаволаи имзошуда барои PUT.
 *
 * @param {string} key роҳи файл дар бакет
 * @param {number} expiresInSeconds мӯҳлати эътибор
 * @returns {{uploadUrl: string, fileUrl: string|null, key: string}}
 */
function presignPut(key, expiresInSeconds = 900) {
  if (!isConfigured()) throw new Error('R2 танзим нашудааст');

  const host = endpointHost();
  const now = new Date();
  const amzDate = now.toISOString().replace(/[:-]|\.\d{3}/g, '');
  const dateStamp = amzDate.slice(0, 8);
  const region = 'auto';
  const service = 's3';
  const scope = `${dateStamp}/${region}/${service}/aws4_request`;

  const canonicalUri = `/${bucketName()}/${encodePath(key)}`;
  const query = {
    'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
    'X-Amz-Credential': `${config.accessKeyId}/${scope}`,
    'X-Amz-Date': amzDate,
    'X-Amz-Expires': String(expiresInSeconds),
    'X-Amz-SignedHeaders': 'host',
  };
  const canonicalQuery = Object.keys(query)
    .sort()
    .map((k) => `${encodeURIComponent(k)}=${encodeURIComponent(query[k])}`)
    .join('&');

  const canonicalRequest = [
    'PUT',
    canonicalUri,
    canonicalQuery,
    `host:${host}\n`,
    'host',
    UNSIGNED_PAYLOAD,
  ].join('\n');

  const stringToSign = [
    'AWS4-HMAC-SHA256',
    amzDate,
    scope,
    sha256Hex(canonicalRequest),
  ].join('\n');

  const dateKey = hmac(`AWS4${config.secretAccessKey}`, dateStamp);
  const regionKey = hmac(dateKey, region);
  const serviceKey = hmac(regionKey, service);
  const signingKey = hmac(serviceKey, 'aws4_request');
  const signature = crypto.createHmac('sha256', signingKey).update(stringToSign).digest('hex');

  const uploadUrl = `https://${host}${canonicalUri}?${canonicalQuery}&X-Amz-Signature=${signature}`;
  const base = publicBase();

  return {
    uploadUrl,
    fileUrl: base ? `${base}/${encodePath(key)}` : null,
    key,
  };
}

module.exports = { isConfigured, status, presignPut };
