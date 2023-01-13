import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../api/profile.dart';
import '../library/exceptions.dart';
import '../provider/auth.dart';

class Authorization {
  static Future<void> socialSignIn(
      CredentialProviders provider, WidgetRef ref) async {
    OAuthCredential credential;
    if (provider == CredentialProviders.google) {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) throw Exception('google login failed');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
    } else {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // OAthCredentialのインスタンスを作成
      OAuthProvider oauthProvider = OAuthProvider('apple.com');
      credential = oauthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
    }
    // Once signed in, return the UserCredential
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    await userCredential.user?.reload();
    User? firebaseUser = userCredential.user;
    if (firebaseUser == null) throw Exception('firebase user not found');
    try {
      await ref.read(authProvider.notifier).loginWithFirebase(firebaseUser);
    } on UserNotFoundException {
      String nickName = userCredential.user?.displayName ?? "ユーザー";
      String userName = await ProfileApi.getRandomCustomId();
      await ref
          .read(authProvider.notifier)
          .registerWithFirebase(nickName, userName, firebaseUser);
    }
  }

  static Future<String> registerConfirm(String email, String password) async {
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'weak-password';
      } else if (e.code == 'email-already-in-use') {
        return 'email-used';
      }
    }
    return 'success';
  }

  static Future<String> signInConfirm(String email, String password) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'user-not-found';
      } else if (e.code == 'wrong-password') {
        return 'wrong-password';
      }
    }
    return 'success';
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
