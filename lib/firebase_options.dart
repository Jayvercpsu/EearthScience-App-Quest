// File generated manually to provide desktop Firebase options.
// Keep this in sync with your Firebase project settings.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDZGoJFAGRossb4yAjNd4XNIkw7QJa5Zy0',
    appId: '1:576747306039:android:f1d939b850becbdd0753b2',
    messagingSenderId: '576747306039',
    projectId: 'earth-science-ba100',
    storageBucket: 'earth-science-ba100.firebasestorage.app',
    authDomain: 'earth-science-ba100.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDZGoJFAGRossb4yAjNd4XNIkw7QJa5Zy0',
    appId: '1:576747306039:android:f1d939b850becbdd0753b2',
    messagingSenderId: '576747306039',
    projectId: 'earth-science-ba100',
    storageBucket: 'earth-science-ba100.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDZGoJFAGRossb4yAjNd4XNIkw7QJa5Zy0',
    appId: '1:576747306039:android:f1d939b850becbdd0753b2',
    messagingSenderId: '576747306039',
    projectId: 'earth-science-ba100',
    storageBucket: 'earth-science-ba100.firebasestorage.app',
    iosBundleId: 'com.example.earthScienceGamifiedApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDZGoJFAGRossb4yAjNd4XNIkw7QJa5Zy0',
    appId: '1:576747306039:android:f1d939b850becbdd0753b2',
    messagingSenderId: '576747306039',
    projectId: 'earth-science-ba100',
    storageBucket: 'earth-science-ba100.firebasestorage.app',
    iosBundleId: 'com.example.earthScienceGamifiedApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDZGoJFAGRossb4yAjNd4XNIkw7QJa5Zy0',
    appId: '1:576747306039:android:f1d939b850becbdd0753b2',
    messagingSenderId: '576747306039',
    projectId: 'earth-science-ba100',
    storageBucket: 'earth-science-ba100.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyDZGoJFAGRossb4yAjNd4XNIkw7QJa5Zy0',
    appId: '1:576747306039:android:f1d939b850becbdd0753b2',
    messagingSenderId: '576747306039',
    projectId: 'earth-science-ba100',
    storageBucket: 'earth-science-ba100.firebasestorage.app',
  );
}
