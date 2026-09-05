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
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp();
setGlobalOptions({ region: 'us-central1', maxInstances: 10 });

const db = admin.firestore();
const messaging = admin.messaging();

/** Токени FCM-и корбарро аз ҳуҷҷати users/{uid} мегирад. */
async function getFcmToken(uid) {
  const doc = await db.collection('users').doc(uid).get();
  return doc.exists ? doc.data().fcmToken : null;
}

/** Паёми маълумотии (data-only) FCM-ро ба як корбар мефиристад. */
async function sendDataMessage(uid, data) {
  const token = await getFcmToken(uid);
  if (!token) return;
  try {
    await messaging.send({
      token,
      data,
      android: { priority: 'high' },
      apns: {
        headers: { 'apns-priority': '10', 'apns-push-type': 'background' },
        payload: { aps: { 'content-available': 1 } },
      },
    });
  } catch (err) {
    console.error(`Хатои фиристодани push ба ${uid}:`, err.message);
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
