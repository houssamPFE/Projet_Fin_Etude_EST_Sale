import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDvoklgD7CclghbVM_YC2pKfcSSr38FH_Q',
    appId: '1:421664538216:android:ffe9fc4a413994962dc5dd',
    messagingSenderId: '421664538216',
    projectId: 'nexora-a0e37',
    storageBucket: 'nexora-a0e37.firebasestorage.app',
  );
}
