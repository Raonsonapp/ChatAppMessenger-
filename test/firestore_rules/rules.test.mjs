// Санҷиши қоидаҳои Firestore дар эмулятор — пеш аз фиристодан ба лоиҳаи воқеӣ.
//
// Мақсади асосӣ: боварӣ ҳосил кардан, ки қоидаҳо на танҳо бегонаро манъ
// мекунанд, балки ДАРХОСТҲОИ ХУДИ БАРНОМА-ро низ намешикананд.
import assert from 'node:assert';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import {
  doc, getDoc, setDoc, updateDoc, collection, addDoc,
  query, where, getDocs, deleteDoc,
} from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'demo-chatapp',
  firestore: { host: '127.0.0.1', port: 8181, rules: readFileSync('firestore.rules', 'utf8') },
});

const A = 'userA';
const B = 'userB';
const C = 'userC';
const convoId = [A, B].sort().join('_');

const results = [];
async function check(name, fn) {
  try {
    await fn();
    results.push(['PASS', name]);
  } catch (e) {
    results.push(['FAIL', name, e.message]);
  }
}

await env.clearFirestore();

// Маълумоти ибтидоӣ бе қоидаҳо.
await env.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  await setDoc(doc(db, 'users', A), { name: 'A', phone: '+992111111111' });
  await setDoc(doc(db, 'users', B), { name: 'B', phone: '+992222222222' });
  await setDoc(doc(db, 'users', C), { name: 'C', phone: '+992333333333' });
  await setDoc(doc(db, 'conversations', convoId), {
    participants: [A, B], participantNames: { [A]: 'A', [B]: 'B' },
  });
  await setDoc(doc(db, 'conversations', convoId, 'messages', 'm1'), { text: 'salom', senderId: A });
  await setDoc(doc(db, 'groups', 'g1'), { name: 'G', members: [A, B], admins: [A] });
  await setDoc(doc(db, 'groups', 'g1', 'messages', 'gm1'), { text: 'hi', senderId: A });
  await setDoc(doc(db, 'communities', 'c1'), { name: 'C', members: [A], admins: [A] });
  await setDoc(doc(db, 'channels', 'ch1'), { name: 'Ch', ownerId: A, followers: [A] });
  await setDoc(doc(db, 'statuses', A), { ownerId: A, ownerName: 'A' });
  await setDoc(doc(db, 'statuses', A, 'items', 's1'), { ownerId: A, viewedBy: [] });
  await setDoc(doc(db, 'calls', 'call1'), {
    callerId: A, calleeId: B, participants: [A, B], outcome: 'ringing',
  });
});

const a = env.authenticatedContext(A).firestore();
const b = env.authenticatedContext(B).firestore();
const c = env.authenticatedContext(C).firestore();
const anon = env.unauthenticatedContext().firestore();

// --- Он чизе ки БАРНОМА мекунад, бояд КОР КУНАД ---
await check('A чати худро мехонад', () => assertSucceeds(getDoc(doc(a, 'conversations', convoId))));
await check('A паёмҳои чати худро мехонад', () =>
  assertSucceeds(getDocs(collection(a, 'conversations', convoId, 'messages'))));
await check('A паём мефиристад', () =>
  assertSucceeds(addDoc(collection(a, 'conversations', convoId, 'messages'), { text: 'x', senderId: A })));
await check('A рӯйхати чатҳояшро мегирад (participants arrayContains)', () =>
  assertSucceeds(getDocs(query(collection(a, 'conversations'), where('participants', 'array-contains', A)))));
await check('A сарлавҳаи чатро нав мекунад (unread/pinned)', () =>
  assertSucceeds(setDoc(doc(a, 'conversations', convoId), { lastMessage: 'x', unread: { [B]: 1 } }, { merge: true })));
await check('A профили худро тағйир медиҳад', () =>
  assertSucceeds(setDoc(doc(a, 'users', A), { name: 'A2' }, { merge: true })));
await check('A профили дигаронро мехонад (ҷустуҷӯи контакт)', () =>
  assertSucceeds(getDocs(collection(a, 'users'))));
await check('A паёми ситорадорашро менависад', () =>
  assertSucceeds(setDoc(doc(a, 'users', A, 'starred', 'x1'), { text: 'y' })));
await check('A паёми ситорадорашро мехонад', () =>
  assertSucceeds(getDocs(collection(a, 'users', A, 'starred'))));
await check('A гурӯҳашро мехонад', () => assertSucceeds(getDoc(doc(a, 'groups', 'g1'))));
await check('A ба гурӯҳ паём мефиристад', () =>
  assertSucceeds(addDoc(collection(a, 'groups', 'g1', 'messages'), { text: 'x', senderId: A })));
await check('Дар гурӯҳи «танҳо админҳо» админ навишта метавонад', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'groups', 'g2'), {
      name: 'G2', members: [A, B], admins: [A], onlyAdminsCanSend: true,
    });
  });
  await assertSucceeds(addDoc(collection(a, 'groups', 'g2', 'messages'), { text: 'ok', senderId: A }));
});
await check('Дар гурӯҳи «танҳо админҳо» узви оддӣ навишта НАМЕТАВОНАД', () =>
  assertFails(addDoc(collection(b, 'groups', 'g2', 'messages'), { text: 'no', senderId: B })));
await check('Дар гурӯҳи «танҳо админҳо» узви оддӣ мехонад', () =>
  assertSucceeds(getDocs(collection(b, 'groups', 'g2', 'messages'))));
await check('A рӯйхати гурӯҳҳояшро мегирад', () =>
  assertSucceeds(getDocs(query(collection(a, 'groups'), where('members', 'array-contains', A)))));
await check('A ҷамъиятҳояшро мегирад', () =>
  assertSucceeds(getDocs(query(collection(a, 'communities'), where('members', 'array-contains', A)))));
await check('C каналҳоро мебинад (кашф)', () => assertSucceeds(getDocs(collection(c, 'channels'))));
await check('C ба канал обуна мешавад (танҳо followers)', () =>
  assertSucceeds(updateDoc(doc(c, 'channels', 'ch1'), { followers: [A, C] })));
await check('B навсозии A-ро мебинад', () =>
  assertSucceeds(getDocs(collection(b, 'statuses', A, 'items'))));
await check('B навсозиро ҳамчун дидашуда қайд мекунад', () =>
  assertSucceeds(updateDoc(doc(b, 'statuses', A, 'items', 's1'), { viewedBy: [B] })));
await check('B зангҳои воридотиро мешунавад (calleeId ==)', () =>
  assertSucceeds(getDocs(query(collection(b, 'calls'), where('calleeId', '==', B), where('outcome', '==', 'ringing')))));
await check('A таърихи зангҳояшро мегирад (participants arrayContains)', () =>
  assertSucceeds(getDocs(query(collection(a, 'calls'), where('participants', 'array-contains', A)))));
await check('A занги нав месозад', () =>
  assertSucceeds(addDoc(collection(a, 'calls'), { callerId: A, calleeId: B, participants: [A, B], outcome: 'ringing' })));
await check('B занги воридотиро ҷавоб медиҳад', () =>
  assertSucceeds(updateDoc(doc(b, 'calls', 'call1'), { outcome: 'completed' })));
await check('A паёми мӯҳлаташ гузаштаро нест мекунад', () =>
  assertSucceeds(deleteDoc(doc(a, 'conversations', convoId, 'messages', 'm1'))));

// --- Он чизе ки набояд иҷозат дошта бошад ---
await check('C чати бегонаро хонда НАМЕТАВОНАД', () =>
  assertFails(getDoc(doc(c, 'conversations', convoId))));
await check('C паёмҳои бегонаро хонда НАМЕТАВОНАД', () =>
  assertFails(getDocs(collection(c, 'conversations', convoId, 'messages'))));
await check('C ба чати бегона навишта НАМЕТАВОНАД', () =>
  assertFails(addDoc(collection(c, 'conversations', convoId, 'messages'), { text: 'hack', senderId: C })));
await check('C профили A-ро тағйир дода НАМЕТАВОНАД', () =>
  assertFails(setDoc(doc(c, 'users', A), { name: 'hacked' }, { merge: true })));
await check('C паёмҳои ситорадори A-ро хонда НАМЕТАВОНАД', () =>
  assertFails(getDocs(collection(c, 'users', A, 'starred'))));
await check('C гурӯҳи бегонаро хонда НАМЕТАВОНАД', () =>
  assertFails(getDoc(doc(c, 'groups', 'g1'))));
await check('C ба гурӯҳи бегона навишта НАМЕТАВОНАД', () =>
  assertFails(addDoc(collection(c, 'groups', 'g1', 'messages'), { text: 'hack', senderId: C })));
await check('C ба канали бегона нашр карда НАМЕТАВОНАД', () =>
  assertFails(addDoc(collection(c, 'channels', 'ch1', 'messages'), { text: 'hack' })));
await check('C номи канали бегонаро иваз карда НАМЕТАВОНАД', () =>
  assertFails(updateDoc(doc(c, 'channels', 'ch1'), { name: 'hacked' })));
await check('C навсозии A-ро нест карда НАМЕТАВОНАД', () =>
  assertFails(deleteDoc(doc(c, 'statuses', A, 'items', 's1'))));
await check('C матни навсозии A-ро иваз карда НАМЕТАВОНАД', () =>
  assertFails(updateDoc(doc(c, 'statuses', A, 'items', 's1'), { text: 'hacked' })));
await check('C рӯйхати дидаҳоро пок карда НАМЕТАВОНАД', () =>
  assertFails(updateDoc(doc(c, 'statuses', A, 'items', 's1'), { viewedBy: [] })));
await check('C занги бегонаро хонда НАМЕТАВОНАД', () =>
  assertFails(getDoc(doc(c, 'calls', 'call1'))));
await check('C ҳамаи чатҳоро рӯйхат карда НАМЕТАВОНАД', () =>
  assertFails(getDocs(collection(c, 'conversations'))));
await check('Меҳмони новоридшуда чизе хонда НАМЕТАВОНАД', () =>
  assertFails(getDocs(collection(anon, 'users'))));

await env.cleanup();

let failed = 0;
for (const r of results) {
  if (r[0] === 'FAIL') failed++;
  console.log(`${r[0]}  ${r[1]}${r[2] ? '  -> ' + r[2].split('\n')[0] : ''}`);
}
console.log(`\n${results.length - failed}/${results.length} гузаштанд`);
process.exit(failed === 0 ? 0 : 1);
