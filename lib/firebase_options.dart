import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions барои ин платформа танзим нашудааст. '
          'Танҳо Web ва Android дастгирӣ мешаванд.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDO8rw1NvSAosX7Z0Nj4_eV1hkBAB6OW1A',
    authDomain: 'chatapp-57fb2.firebaseapp.com',
    projectId: 'chatapp-57fb2',
    storageBucket: 'chatapp-57fb2.firebasestorage.app',
    messagingSenderId: '712168365642',
    appId: '1:712168365642:web:6ea9ac370500cc8b6310b8',
    measurementId: 'G-D78QHLSTVN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAi83BIGIYOibG2YcwtYY1Lah9ePkPtLWQ',
    appId: '1:712168365642:android:3bb79f163e73fe9f6310b3',
    messagingSenderId: '712168365642',
    projectId: 'chatapp-57fb2',
    storageBucket: 'chatapp-57fb2.firebasestorage.app',
  );
}
