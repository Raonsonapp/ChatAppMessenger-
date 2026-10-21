import test from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const {
  extractResponseText,
  generateChatReply,
  listConfiguredProviders,
  modelFor,
} = require('./ai_providers.js');

function fakeResponse(body, status = 200) {
  return { ok: status >= 200 && status < 300, status, json: async () => body };
}

test('free-only mode exposes Gemini only even if paid-provider keys exist', () => {
  const providers = listConfiguredProviders({
    GEMINI_API_KEY: 'gemini-secret',
    OPENAI_API_KEY: 'openai-secret',
    XAI_API_KEY: 'xai-secret',
  });
  assert.deepEqual(providers.map((provider) => provider.id), ['gemini']);
  assert.equal(JSON.stringify(providers).includes('secret'), false);
});

test('paid providers appear only after an explicit server-side opt-in', () => {
  const providers = listConfiguredProviders({
    GEMINI_API_KEY: 'gemini-secret',
    OPENAI_API_KEY: 'openai-secret',
    XAI_API_KEY: 'xai-secret',
    ALLOW_PAID_AI_PROVIDERS: 'true',
  });
  assert.deepEqual(providers.map((provider) => provider.id), ['gemini', 'openai', 'grok']);
  assert.equal(JSON.stringify(providers).includes('secret'), false);
});

test('default models match documented provider model IDs', () => {
  assert.equal(modelFor('gemini', {}), 'gemini-2.5-flash');
  assert.equal(modelFor('openai', {}), 'gpt-5-mini');
  assert.equal(modelFor('grok', {}), 'grok-4.7');
});

test('Gemini provider returns text and uses configured key/model', async () => {
  let requestedUrl = '';
  let body;
  const reply = await generateChatReply({
    provider: 'gemini',
    messages: [{ role: 'user', text: 'Салом' }],
    env: { GEMINI_API_KEY: 'not-real-test-key', GEMINI_CHAT_MODEL: 'gemini-test-model' },
    fetchImpl: async (url, options) => {
      requestedUrl = String(url);
      body = JSON.parse(options.body);
      return fakeResponse({ candidates: [{ content: { parts: [{ text: 'Салом!' }] } }] });
    },
  });
  assert.equal(reply, 'Салом!');
  assert.match(requestedUrl, /gemini-test-model:generateContent/);
  assert.equal(new URL(requestedUrl).searchParams.get('key'), 'not-real-test-key');
  assert.equal(body.contents[0].parts[0].text, 'Салом');
});

test('OpenAI provider uses Responses API and extracts output text', async () => {
  let requestedUrl = '';
  let body;
  const reply = await generateChatReply({
    provider: 'openai',
    messages: [{ role: 'user', text: 'Explain gravity' }],
    env: { OPENAI_API_KEY: 'not-real-test-key', OPENAI_MODEL: 'gpt-test-model' },
    fetchImpl: async (url, options) => {
      requestedUrl = String(url);
      body = JSON.parse(options.body);
      assert.equal(options.headers.Authorization, 'Bearer not-real-test-key');
      return fakeResponse({ output: [{ type: 'message', content: [{ type: 'output_text', text: 'Gravity pulls.' }] }] });
    },
  });
  assert.equal(requestedUrl, 'https://api.openai.com/v1/responses');
  assert.equal(body.model, 'gpt-test-model');
  assert.equal(reply, 'Gravity pulls.');
});

test('Grok provider uses the xAI Responses API', async () => {
  let requestedUrl = '';
  const reply = await generateChatReply({
    provider: 'grok',
    messages: [{ role: 'user', text: 'Hello' }],
    env: { XAI_API_KEY: 'not-real-test-key', XAI_MODEL: 'grok-test-model' },
    fetchImpl: async (url, options) => {
      requestedUrl = String(url);
      const body = JSON.parse(options.body);
      assert.equal(body.model, 'grok-test-model');
      return fakeResponse({ output_text: 'Hello from Grok.' });
    },
  });
  assert.equal(requestedUrl, 'https://api.x.ai/v1/responses');
  assert.equal(reply, 'Hello from Grok.');
});

test('an unconfigured provider fails before making a network request', async () => {
  let calls = 0;
  await assert.rejects(
    generateChatReply({
      provider: 'openai',
      messages: [{ role: 'user', text: 'test' }],
      env: {},
      fetchImpl: async () => { calls++; return fakeResponse({}); },
    }),
    (error) => error.status === 503 && error.code === 'provider-not-configured',
  );
  assert.equal(calls, 0);
});

test('unsupported provider fails explicitly', async () => {
  await assert.rejects(
    generateChatReply({
      provider: 'random',
      messages: [{ role: 'user', text: 'test' }],
      env: { GEMINI_API_KEY: 'not-real-test-key' },
      fetchImpl: async () => fakeResponse({}),
    }),
    (error) => error.status === 400 && error.code === 'provider-not-supported',
  );
});

test('provider rate limit remains distinguishable', async () => {
  await assert.rejects(
    generateChatReply({
      provider: 'openai',
      messages: [{ role: 'user', text: 'test' }],
      env: { OPENAI_API_KEY: 'not-real-test-key' },
      fetchImpl: async () => fakeResponse({ error: { message: 'limited' } }, 429),
    }),
    (error) => error.status === 429 && error.code === 'provider-rate-limited',
  );
});

test('web context is appended to latest user message only', async () => {
  let body;
  await generateChatReply({
    provider: 'openai',
    messages: [
      { role: 'user', text: 'older question' },
      { role: 'assistant', text: 'older answer' },
      { role: 'user', text: 'latest question' },
    ],
    webContext: '\\nWeb evidence: https://example.com',
    env: { OPENAI_API_KEY: 'not-real-test-key' },
    fetchImpl: async (_url, options) => {
      body = JSON.parse(options.body);
      return fakeResponse({ output_text: 'answer' });
    },
  });
  assert.equal(body.input[3].content, 'latest question\\nWeb evidence: https://example.com');
  assert.equal(body.input[2].content, 'older answer');
});
test('extractResponseText handles Responses API and compatible chat completions', () => {
  assert.equal(extractResponseText({ output_text: 'direct' }), 'direct');
  assert.equal(
    extractResponseText({ choices: [{ message: { content: [{ text: 'part A' }, { text: 'part B' }] } }] }),
    'part Apart B',
  );
});
