import assert from 'node:assert/strict';
import test from 'node:test';

import botBuilder from './bot_builder.js';

const { validateBotDefinition } = botBuilder;

test('accepts a basic bot configuration', () => {
  const result = validateBotDefinition({
    name: 'Ёрдамчӣ',
    description: 'Ба саволҳо ҷавоб медиҳад',
    task: 'general',
    instructions: 'Боадабона ҷавоб деҳ',
    actions: ['answer_questions'],
  });
  assert.equal(result.ok, true);
  assert.equal(result.value.status, 'draft');
});

test('requires donation guide for diamond donation bots', () => {
  assert.deepEqual(
    validateBotDefinition({
      name: 'Diamond guide',
      task: 'diamond_donation',
      actions: ['answer_questions'],
    }),
    { ok: false, error: 'donation-guide-required' },
  );
});

test('rejects unknown actions and tasks', () => {
  assert.equal(validateBotDefinition({ name: 'Bot', task: 'shell', actions: [] }).ok, false);
  assert.equal(validateBotDefinition({ name: 'Bot', task: 'general', actions: ['run-code'] }).ok, false);
});

test('enforces field lengths', () => {
  assert.equal(validateBotDefinition({ name: 'x', task: 'general', actions: [] }).error, 'name-invalid');
  assert.equal(validateBotDefinition({ name: 'Valid', task: 'general', description: 'd'.repeat(161), actions: [] }).error, 'description-too-long');
  assert.equal(validateBotDefinition({ name: 'Valid', task: 'general', instructions: 'i'.repeat(2001), actions: [] }).error, 'instructions-too-long');
});

test('deduplicates allowed actions', () => {
  const result = validateBotDefinition({ name: 'FAQ', task: 'faq', actions: ['faq', 'faq'] });
  assert.equal(result.ok, true);
  assert.deepEqual(result.value.actions, ['faq']);
});

test('rejects non-object input', () => {
  assert.deepEqual(validateBotDefinition(null), { ok: false, error: 'body-invalid' });
});
