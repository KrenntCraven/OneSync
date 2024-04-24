// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBW4U268NXJZ2VEkNC_58Zb763zjR0J6hg',
    appId: '1:1055546308486:web:2591f2fdde838aad425e07',
    messagingSenderId: '1055546308486',
    projectId: 'onesync-b234d',
    authDomain: 'onesync-b234d.firebaseapp.com',
    storageBucket: 'onesync-b234d.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAjzzVsewvrDwvYG9urLB8l2F7cpRqbn5A',
    appId: '1:1055546308486:android:19f1b31430a7bec8425e07',
    messagingSenderId: '1055546308486',
    projectId: 'onesync-b234d',
    storageBucket: 'onesync-b234d.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDPA0c4zEcUrhvjUo0dMCaSxBn-Dths73k',
    appId: '1:1055546308486:ios:2230c43233fab82a425e07',
    messagingSenderId: '1055546308486',
    projectId: 'onesync-b234d',
    storageBucket: 'onesync-b234d.appspot.com',
    iosBundleId: 'com.thesis3.onesync',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBW4U268NXJZ2VEkNC_58Zb763zjR0J6hg',
    appId: '1:1055546308486:web:95b76b2d8465dd60425e07',
    messagingSenderId: '1055546308486',
    projectId: 'onesync-b234d',
    authDomain: 'onesync-b234d.firebaseapp.com',
    storageBucket: 'onesync-b234d.appspot.com',
  );
}