import 'package:firebase_core/firebase_core.dart';

/// ЭЗОҲ: Ҳозир ҳамаи платформаҳо (Android, iOS, Web) як танзими ягонаро
/// истифода мебаранд — калидҳои проекти Firebase (chatapp-57fb2). Ин кор
/// мекунад, чунки Firebase бо нобаёт калидро ба платформа қулф намекунад
/// (агар шумо худ дар Google Cloud Console маҳдудият нагузошта бошед).
/// Дар оянда, агар хоҳед хусусиятҳои махсуси Android (push notifications,
/// Crashlytics ва ғ.) илова кунед, метавонед апп-и алоҳидаи Android дар
/// Firebase Console сабт карда, ин файлро бо калидҳои он иваз кунед.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDO8rw1NvSAosX7Z0Nj4_eV1hkBAB6OW1A',
    authDomain: 'chatapp-57fb2.firebaseapp.com',
    projectId: 'chatapp-57fb2',
    storageBucket: 'chatapp-57fb2.firebasestorage.app',
    messagingSenderId: '712168365642',
    appId: '1:712168365642:web:6ea9ac370500cc8b6310b8',
    measurementId: 'G-D78QHLSTVN',
  );
}
