/**
 * Two-provider web search for ChatApp ChatAI.
 *
 * Primary: Brave Search API.
 * Fallback: Tavily Search API.
 *
 * Provider keys are read only from server environment variables.
 * Each provider is attempted in order; failure of one does not prevent the
 * other from being tried. Returned snippets are untrusted web content and
 * must be treated as evidence, not instructions.
 */
const SEARCH_TIMEOUT_MS = 8000;
const SEARCH_MAX_RESULTS = 5;
const MAX_QUERY_LENGTH = 400;

function cleanQuery(value) {
  return String(value ?? '').replace(/\s+/g, ' ').trim().slice(0, MAX_QUERY_LENGTH);
}

function safeHttpUrl(value) {
  try {
    const url = new URL(String(value ?? ''));
    return url.protocol === 'https:' || url.protocol === 'http:' ? url.toString() : null;
  } catch {
    return null;
  }
}

function normalizeResult({ title, url, snippet, source }) {
  const safeUrl = safeHttpUrl(url);
  if (!safeUrl) return null;
  return {
    title: String(title ?? '').trim().slice(0, 240) || safeUrl,
    url: safeUrl,
    snippet: String(snippet ?? '').replace(/\s+/g, ' ').trim().slice(0, 1200),
    source: String(source ?? new URL(safeUrl).hostname).slice(0, 160),
  };
}

async function fetchJson(url, options = {}) {
  const response = await fetch(url, {
    ...options,
    signal: AbortSignal.timeout(SEARCH_TIMEOUT_MS),
  });
  if (!response.ok) {
    const error = new Error(`Search provider returned HTTP ${response.status}`);
    error.status = response.status;
    throw error;
  }
  return response.json();
}

async function braveSearch(query, apiKey) {
  const url = new URL('https://api.search.brave.com/res/v1/web/search');
  url.searchParams.set('q', query);
  url.searchParams.set('count', String(SEARCH_MAX_RESULTS));
  const data = await fetchJson(url, {
    headers: {
      Accept: 'application/json',
      'X-Subscription-Token': apiKey,
    },
  });
  return (data?.web?.results ?? [])
    .map((item) => normalizeResult({
      title: item.title,
      url: item.url,
      snippet: item.description,
      source: item.profile?.long_name ?? item.profile?.name,
    }))
    .filter(Boolean)
    .slice(0, SEARCH_MAX_RESULTS);
}

async function tavilySearch(query, apiKey) {
  const data = await fetchJson('https://api.tavily.com/search', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      api_key: apiKey,
      query,
      search_depth: 'basic',
      max_results: SEARCH_MAX_RESULTS,
      include_answer: false,
      include_raw_content: false,
    }),
  });
  return (data?.results ?? [])
    .map((item) => normalizeResult({
      title: item.title,
      url: item.url,
      snippet: item.content,
    }))
    .filter(Boolean)
    .slice(0, SEARCH_MAX_RESULTS);
}

/**
 * Search using primary and fallback providers. Provider order can be changed
 * using CHAT_AI_SEARCH_PRIMARY=brave|tavily. Returns {results, provider, errors}.
 */
export async function searchWeb(queryValue, env = process.env) {
  const query = cleanQuery(queryValue);
  if (query.length < 2) {
    return { results: [], provider: null, errors: [{ provider: 'validation', reason: 'query-too-short' }] };
  }

  const providers = {
    brave: { key: env.BRAVE_SEARCH_API_KEY, search: braveSearch },
    tavily: { key: env.TAVILY_API_KEY, search: tavilySearch },
  };
  const primary = String(env.CHAT_AI_SEARCH_PRIMARY ?? 'brave').toLowerCase() === 'tavily'
    ? 'tavily'
    : 'brave';
  const order = [primary, primary === 'brave' ? 'tavily' : 'brave'];
  const errors = [];

  for (const name of order) {
    const provider = providers[name];
    if (!provider.key) {
      errors.push({ provider: name, reason: 'not-configured' });
      continue;
    }
    try {
      const results = await provider.search(query, provider.key);
      if (results.length) return { results, provider: name, errors };
      errors.push({ provider: name, reason: 'no-results' });
    } catch (error) {
      errors.push({
        provider: name,
        reason: error?.name === 'TimeoutError' || error?.name === 'AbortError'
          ? 'timeout'
          : 'request-failed',
      });
    }
  }

  return { results: [], provider: null, errors };
}

export const __testables = { cleanQuery, safeHttpUrl, normalizeResult };
