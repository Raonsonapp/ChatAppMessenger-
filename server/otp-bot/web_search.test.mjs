import test from 'node:test';
import assert from 'node:assert/strict';
import { __testables, searchWeb } from './web_search.js';

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
