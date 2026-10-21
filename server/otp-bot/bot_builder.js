const TASKS = new Set([
  'general',
  'diamond_donation',
  'faq',
  'support',
  'custom',
]);

const ACTIONS = new Set([
  'answer_questions',
  'faq',
  'donation_guide',
  'collect_feedback',
  'handoff_to_admin',
]);

function validateBotDefinition(input) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    return { ok: false, error: 'body-invalid' };
  }

  const name = typeof input.name === 'string' ? input.name.trim() : '';
  const description = typeof input.description === 'string' ? input.description.trim() : '';
  const task = typeof input.task === 'string' ? input.task : '';
  const instructions = typeof input.instructions === 'string' ? input.instructions.trim() : '';
  const actions = Array.isArray(input.actions) ? [...new Set(input.actions)] : [];

  if (name.length < 2 || name.length > 40) return { ok: false, error: 'name-invalid' };
  if (description.length > 160) return { ok: false, error: 'description-too-long' };
  if (!TASKS.has(task)) return { ok: false, error: 'task-invalid' };
  if (instructions.length > 2000) return { ok: false, error: 'instructions-too-long' };
  if (actions.length > 5 || actions.some((action) => typeof action !== 'string' || !ACTIONS.has(action))) {
    return { ok: false, error: 'actions-invalid' };
  }
  if (task === 'diamond_donation' && !actions.includes('donation_guide')) {
    return { ok: false, error: 'donation-guide-required' };
  }

  return {
    ok: true,
    value: {
      name,
      description,
      task,
      instructions,
      actions,
      status: 'draft',
    },
  };
}

module.exports = { validateBotDefinition };
