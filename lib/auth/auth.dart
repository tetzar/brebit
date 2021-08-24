import 'package:firebase_auth/firebase_auth.dart';

import 'dart:async';

class Authorization{
  static Future<String> registerConfirm(String email, String password) async{
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'weak-password';
      } else if (e.code == 'email-already-in-use') {
        return 'email-used';
      }
    } catch (e) {
      return e;
    }
    return 'success';
  }

  static Future<String> signInConfirm(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'user-not-found';
      } else if (e.code == 'wrong-password') {
        return 'wrong-password';
      }
    } catch (e) {
      return e;
    }
    return 'success';
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

}
