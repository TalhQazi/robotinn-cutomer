import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'constants/app_constants.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: AppConstants.googleMapsApiKey,
    appId: '1:301557654113:web:48a7321a59fb1684d1c020',
    messagingSenderId: '301557654113',
    projectId: 'robotin-2a51b',
    storageBucket: 'robotin-2a51b.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: AppConstants.googleMapsApiKey,
    appId: '1:301557654113:android:25af696c4c065d4bd1c020',
    messagingSenderId: '301557654113',
    projectId: 'robotin-2a51b',
    storageBucket: 'robotin-2a51b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: AppConstants.googleMapsApiKey,
    appId: '1:301557654113:ios:6c31a7c5b61e25e9d1c020',
    messagingSenderId: '301557654113',
    projectId: 'robotin-2a51b',
    storageBucket: 'robotin-2a51b.firebasestorage.app',
  );
}
