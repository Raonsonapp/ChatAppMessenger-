import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions барои ин платформа ҳоло танзим нашудааст. '
      'Лутфан аввал дар FlutLab/Web озмоиш кунед.',
    );
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
}
