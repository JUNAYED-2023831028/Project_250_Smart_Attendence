import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
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
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBU4PeIdfAfaD_tkuWyNbG7tYALK3oYzEQ',
    appId: '1:1071499684582:web:1d463df6d2eb30e5726927',
    messagingSenderId: '1071499684582',
    projectId: 'add-project-42276',
    authDomain: 'add-project-42276.firebaseapp.com',
    storageBucket: 'add-project-42276.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDSCPFhKbtZNNS6akQbaA_nwo9JsbpIPns',
    appId: '1:1071499684582:android:e52b96f3d028b803726927',
    messagingSenderId: '1071499684582',
    projectId: 'add-project-42276',
    storageBucket: 'add-project-42276.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCpq4aNMRyimFBAMpt3GJi7xOH8XokaZZ8',
    appId: '1:1071499684582:ios:7e601815120fa76e726927',
    messagingSenderId: '1071499684582',
    projectId: 'add-project-42276',
    storageBucket: 'add-project-42276.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCpq4aNMRyimFBAMpt3GJi7xOH8XokaZZ8',
    appId: '1:1071499684582:ios:7e601815120fa76e726927',
    messagingSenderId: '1071499684582',
    projectId: 'add-project-42276',
    storageBucket: 'add-project-42276.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBU4PeIdfAfaD_tkuWyNbG7tYALK3oYzEQ',
    appId: '1:1071499684582:web:d4aa506413cae508726927',
    messagingSenderId: '1071499684582',
    projectId: 'add-project-42276',
    authDomain: 'add-project-42276.firebaseapp.com',
    storageBucket: 'add-project-42276.firebasestorage.app',
  );
}