import test from 'node:test';
import assert from 'node:assert/strict';
import webSearchModule from './web_search.js';
const { __testables, searchWeb, shouldSearchWeb } = webSearchModule;

test('cleans and bounds the query', () => {
  assert.equal(__testables.cleanQuery('  hello   world  '), 'hello world');
  assert.equal(__testables.cleanQuery('x'.repeat(500)).length, 400);
});

test('only accepts HTTP and HTTPS result URLs', () => {
  assert.equal(__testables.safeHttpUrl('javascript:alert(1)'), null);
  assert.equal(__testables.safeHttpUrl('file:///etc/passwd'), null);
  assert.equal(__testables.safeHttpUrl('https://example.com'), 'https://example.com/');
});

test('normalizes safe results and rejects unsafe URLs', () => {
  assert.equal(__testables.normalizeResult({ url: 'javascript:alert(1)' }), null);
  const item = __testables.normalizeResult({
    title: ' Example ',
    url: 'https://example.com/a',
    snippet: 'hello   from   web',
  });
  assert.equal(item.title, 'Example');
  assert.equal(item.snippet, 'hello from web');
  assert.equal(item.source, 'example.com');
});

test('rejects an empty query without making a network request', async () => {
  const result = await searchWeb(' ', {});
  assert.deepEqual(result.results, []);
  assert.equal(result.provider, null);
  assert.equal(result.errors[0].reason, 'query-too-short');
});

test('reports missing provider configuration without a network request', async () => {
  const result = await searchWeb('weather tomorrow', {});
  assert.deepEqual(result.results, []);
  assert.equal(result.provider, null);
  assert.deepEqual(result.errors.map((e) => e.reason), ['not-configured', 'not-configured']);
});

test('detects explicit internet search and fresh-information intent', () => {
  assert.equal(shouldSearchWeb('Please search the web for this'), true);
  assert.equal(shouldSearchWeb('Имрӯз ҳаво чӣ хел мешавад?'), true);
  assert.equal(shouldSearchWeb('Поищи последние новости'), true);
  assert.equal(shouldSearchWeb('Салом, чӣ хабар?'), true);
  assert.equal(shouldSearchWeb('Салом'), false);
});

test('uses fallback provider if the primary returns an HTTP error', async (t) => {
  const originalFetch = globalThis.fetch;
  t.after(() => { globalThis.fetch = originalFetch; });
  const calls = [];
  globalThis.fetch = async (url, options = {}) => {
    calls.push(String(url));
    if (String(url).includes('api.search.brave.com')) {
      return { ok: false, status: 401, json: async () => ({}) };
    }
    assert.equal(String(url), 'https://api.tavily.com/search');
    assert.equal(options.method, 'POST');
    return {
      ok: true,
      status: 200,
      json: async () => ({
        results: [{ title: 'Result', url: 'https://example.com', content: 'Useful snippet' }],
      }),
    };
  };
  const result = await searchWeb('latest science news', {
    BRAVE_SEARCH_API_KEY: 'test-primary-key',
    TAVILY_API_KEY: 'test-fallback-key',
    CHAT_AI_SEARCH_PRIMARY: 'brave',
  });
  assert.equal(result.provider, 'tavily');
  assert.equal(result.results.length, 1);
  assert.equal(result.errors[0].reason, 'request-failed');
  assert.equal(calls.length, 2);
});

test('does not call fallback when primary returns results', async (t) => {
  const originalFetch = globalThis.fetch;
  t.after(() => { globalThis.fetch = originalFetch; });
  let calls = 0;
  globalThis.fetch = async () => {
    calls++;
    return {
      ok: true,
      status: 200,
      json: async () => ({
        web: { results: [{ title: 'Primary result', url: 'https://example.com', description: 'Snippet' }] },
      }),
    };
  };
  const result = await searchWeb('latest science news', {
    BRAVE_SEARCH_API_KEY: 'test-primary-key',
    TAVILY_API_KEY: 'test-fallback-key',
    CHAT_AI_SEARCH_PRIMARY: 'brave',
  });
  assert.equal(result.provider, 'brave');
  assert.equal(calls, 1);
});
