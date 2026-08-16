import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDBXhxg8kEADmNwyf8SyI6yszfL3mPEdiQ',
    appId: '1:171497972514:web:c32fbeb42061def491fb7b',
    messagingSenderId: '171497972514',
    projectId: 'society-manager-baf34',
    authDomain: 'society-manager-baf34.firebaseapp.com',
    storageBucket: 'society-manager-baf34.firebasestorage.app',
    measurementId: 'G-CT4533Q154',
  );
}
