// Firebase configuration, mirroring ios/Runner/GoogleService-Info.plist and
// android/app/google-services.json. Passed explicitly to Firebase.initializeApp
// so initialization does not depend on the native config files being bundled
// (the iOS plist was not added to the Xcode target).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for $defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCOWMqB1XJQw6yguzIy1p8qanUUUFbCyAc',
    appId: '1:731924447077:android:512896cc80a44691666b8c',
    messagingSenderId: '731924447077',
    projectId: 'minimumz',
    storageBucket: 'minimumz.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAJ8HFMqmryJ8uUWmYBKDymP4HsNt1N9UI',
    appId: '1:731924447077:ios:0d92843c56d3c829666b8c',
    messagingSenderId: '731924447077',
    projectId: 'minimumz',
    storageBucket: 'minimumz.firebasestorage.app',
    iosBundleId: 'com.store.minimumz',
  );
}
