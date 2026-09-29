/**
 * Cloud Functions барои push-огоҳиномаҳои воқеии ChatApp.
 *
 * Ин функсияҳо дар клиент (Flutter) намерасанд — бояд алоҳида бо
 * Firebase CLI ҷойгир (deploy) карда шаванд:
 *
 *   npm install -g firebase-tools
 *   firebase login
 *   cd functions && npm install
 *   firebase deploy --only functions
 *
 * ЭЗОҲ: Cloud Functions (насли 2) ба нақшаи Blaze (pay-as-you-go) ниёз
 * дорад — нақшаи ройгони Spark кофӣ нест, ҳарчанд истифодаи воқеӣ дар
 * доираи ҳадди ройгони Blaze низ бепул мемонад.
 *
 * ДИҚҚАТ: ин роҳи ИВАЗКУНАНДА аст. Барнома аллакай огоҳиномаҳоро тавассути
 * сервери худамон (server/otp-bot, `POST /api/notify`) мефиристад, ки ба
 * Blaze ниёз надорад. Агар ин функсияҳо ҷойгир карда шаванд, корбар ДУ
 * огоҳинома мегирад — якеро интихоб кунед:
 *   • сервери худамон (ҳозир фаъол) — ин файлро ҷойгир НАКУНЕД;
 *   • ё Cloud Functions — он гоҳ даъватҳои `PushService`-ро аз барнома
 *     бардоред.
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp();
setGlobalOptions({ region: 'us-central1', maxInstances: 10 });

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Ҳамаи токенҳои дастгоҳҳои корбар.
 *
 * Корбар метавонад аз якчанд дастгоҳ ворид шавад. Пештар танҳо як майдон
 * хонда мешуд ва дастгоҳҳои дигар огоҳинома намегирифтанд.
 */
async function getFcmTokens(uid) {
  const doc = await db.collection('users').doc(uid).get();
  if (!doc.exists) return [];
  const info = doc.data();
  const list = Array.isArray(info.fcmTokens) ? info.fcmTokens : [];
  const legacy = info.fcmToken ? [info.fcmToken] : [];
  return [...new Set([...list, ...legacy])].filter((t) => typeof t === 'string' && t);
}

/** Паёми маълумотии (data-only) FCM-ро ба ҲАМАИ дастгоҳҳои корбар мефиристад. */
async function sendDataMessage(uid, data) {
  const tokens = await getFcmTokens(uid);
  if (tokens.length === 0) return;

  const response = await messaging.sendEachForMulticast({
    tokens,
    data,
    android: { priority: 'high' },
    apns: {
      headers: { 'apns-priority': '10', 'apns-push-type': 'background' },
      payload: { aps: { 'content-available': 1 } },
    },
  });

  // Токенҳои бекоршуда тоза мешаванд — танҳо ҳамон дастгоҳ, на ҳама.
  const stale = [];
  response.responses.forEach((item, index) => {
    if (!item.success &&
        item.error?.code === 'messaging/registration-token-not-registered') {
      stale.push(tokens[index]);
    }
  });
  if (stale.length > 0) {
    await db.collection('users').doc(uid).update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove(...stale),
    }).catch(() => {});
  }
}

/** Паёми шахсӣ (conversations/{id}/messages/{id}) → push ба тарафи дигар. */
exports.onDirectMessageCreated = onDocumentCreated(
  'conversations/{conversationId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data();
    if (!message) return;
    const conversationId = event.params.conversationId;

    const convoDoc = await db.collection('conversations').doc(conversationId).get();
    const convo = convoDoc.data();
    if (!convo) return;

    const senderId = message.senderId;
    const recipientId = (convo.participants || []).find((p) => p !== senderId);
    if (!recipientId) return;

    const senderName = (convo.participantNames || {})[senderId] || 'Корбар';

    await sendDataMessage(recipientId, {
      type: 'chat_message',
      kind: 'direct',
      threadId: conversationId,
      threadPath: `conversations/${conversationId}`,
      threadName: senderName,
      senderId,
      senderName,
      text: message.text || '',
    });
  }
);

/** Паёми гурӯҳӣ (groups/{id}/messages/{id}) → push ба ҳамаи аъзои дигар. */
exports.onGroupMessageCreated = onDocumentCreated(
  'groups/{groupId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data();
    if (!message) return;
    const groupId = event.params.groupId;

    const groupDoc = await db.collection('groups').doc(groupId).get();
    const group = groupDoc.data();
    if (!group) return;

    const senderId = message.senderId;
    const senderName = (group.memberNames || {})[senderId] || 'Корбар';
    const members = (group.members || []).filter((uid) => uid !== senderId);

    await Promise.all(
      members.map((uid) =>
        sendDataMessage(uid, {
          type: 'chat_message',
          kind: 'group',
          threadId: groupId,
          threadPath: `groups/${groupId}`,
          threadName: group.name || 'Гурӯҳ',
          senderId,
          senderName,
          text: message.text || '',
        })
      )
    );
  }
);

/** Паёми ҷамъиятӣ (communities/{id}/messages/{id}) → push ба аъзои дигар. */
exports.onCommunityMessageCreated = onDocumentCreated(
  'communities/{communityId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data();
    if (!message) return;
    const communityId = event.params.communityId;

    const communityDoc = await db.collection('communities').doc(communityId).get();
    const community = communityDoc.data();
    if (!community) return;

    const senderId = message.senderId;
    const senderName = (community.memberNames || {})[senderId] || 'Корбар';
    const members = (community.members || []).filter((uid) => uid !== senderId);

    await Promise.all(
      members.map((uid) =>
        sendDataMessage(uid, {
          type: 'chat_message',
          kind: 'community',
          threadId: communityId,
          threadPath: `communities/${communityId}`,
          threadName: community.name || 'Ҷамъият',
          senderId,
          senderName,
          text: message.text || '',
        })
      )
    );
  }
);

/** Занги нав (calls/{id}, outcome == 'ringing') → push ба гиранда. */
exports.onCallCreated = onDocumentCreated('calls/{callId}', async (event) => {
  const call = event.data?.data();
  if (!call || call.outcome !== 'ringing') return;

  await sendDataMessage(call.calleeId, {
    type: 'incoming_call',
    callId: event.params.callId,
    callerId: call.callerId,
    callerName: call.callerName || 'Корбар',
    callType: call.type || 'audio',
  });
});
