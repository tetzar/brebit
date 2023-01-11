import 'dart:async';
import 'dart:io';

import 'package:brebit/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../api/auth.dart';
import '../../../library/exceptions.dart';
import '../../../provider/auth.dart';
import '../../../route/route.dart';
import '../general/loading.dart';
import '../widgets/app-bar.dart';
import '../widgets/dialog.dart';
import '../widgets/text-field.dart';
import 'name-form.dart';


class Login extends StatelessWidget {
  final String? email;

  Login({this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(context: context, titleText: 'サインイン'),
      body: LoginForm(email),
      backgroundColor: Theme.of(context).primaryColor,
    );
  }
}

class LoginFormProviderState {
  bool? userNameOrEmail;
  bool? password;

  LoginFormProviderState copyWith({bool? userNameOrEmail, bool? password}) {
    return LoginFormProviderState()
        ..userNameOrEmail = userNameOrEmail ?? this.userNameOrEmail
        ..password = password ?? this.password;
  }
}

class LoginFormProvider extends StateNotifier<LoginFormProviderState> {
  LoginFormProvider(LoginFormProviderState state) : super(state);

  bool get userNameOrEmail {
    return this.state.userNameOrEmail ?? false;
  }

  bool get password {
    return this.state.password ?? false;
  }

  set userNameOrEmail(bool s) {
    if (this.userNameOrEmail != s) {
      this.state = state.copyWith(userNameOrEmail: s);
    }
  }

  set password(bool s) {
    if (this.password != s) {
      this.state = state.copyWith(password: s);
    }
  }

  bool savable() {
    return (this.state.password ?? false) &&
        (this.state.userNameOrEmail ?? false);
  }
}

final _loginFormProvider = StateNotifierProvider.autoDispose(
    (ref) => LoginFormProvider(LoginFormProviderState()));

class LoginForm extends ConsumerStatefulWidget {
  final String? email;

  LoginForm(this.email);

  @override
  LoginFormState createState() => LoginFormState();
}

class LoginFormState extends ConsumerState<LoginForm> {
  late List<GlobalKey<FormState>> _keys;
  late FocusNode _passwordFocusNode;
  late FocusNode _nameFocusNode;

  String userNameOrEmail = '';
  String password = '';
  String? _userNameOrEmailMessage;
  String? _passwordMessage;

  String get userNameOrEmailMessage {
    return _userNameOrEmailMessage ?? '';
  }

  String get passwordMessage {
    return _passwordMessage ?? '';
  }

  set userNameOrEmailMessage(String message) {
    this._userNameOrEmailMessage = message;
  }

  set passwordMessage(String message) {
    this._passwordMessage = message;
  }

  @override
  void initState() {
    _keys = [
      GlobalKey<FormState>(),
      GlobalKey<FormState>(),
    ];
    _nameFocusNode = new FocusNode();
    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus) {
        _keys[0].currentState?.validate();
      }
    });
    _passwordFocusNode = new FocusNode();
    userNameOrEmailMessage = '';
    passwordMessage = '';
    if (widget.email != null) {
      ref.read(_loginFormProvider.notifier).userNameOrEmail =
          isEmail(widget.email) || isUserName(widget.email);
    }
    super.initState();
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MyHookBottomFixedButton(
      provider: _loginFormProvider,
      enable: () {
        return ref.read(_loginFormProvider.notifier).savable();
      },
      onTapped: () async {
        _nameFocusNode.unfocus();
        _passwordFocusNode.unfocus();
        await submit(context);
      },
      label: 'サインイン',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Form(
              key: _keys[0],
              child: MyTextField(
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (text) {
                  _nameFocusNode.unfocus();
                  _passwordFocusNode.requestFocus();
                },
                focusNode: _nameFocusNode,
                initialValue: widget.email,
                label: 'IDまたはメールアドレス',
                keyboardType: TextInputType.emailAddress,
                inputFormatter: [
                  FilteringTextInputFormatter.allow(RegExp(r"^[\x00-\x7F]+$"))
                ],
                onChanged: (text) {
                  if (userNameOrEmailMessage.length > 0) {
                    String _p = userNameOrEmailMessage;
                    userNameOrEmailMessage = '';
                    return _p;
                  }
                  if (text.length == 0) {
                    ref.read(_loginFormProvider.notifier).userNameOrEmail = false;
                    return '入力してください';
                  }
                  if (isEmail(text) || isUserName(text)) {
                    ref.read(_loginFormProvider.notifier).userNameOrEmail = true;
                    return null;
                  }
                  ref.read(_loginFormProvider.notifier).userNameOrEmail = false;
                  return '正しく入力してください';
                },
                validate: (text) {
                  if (userNameOrEmailMessage.length > 0) {
                    String _p = userNameOrEmailMessage;
                    userNameOrEmailMessage = '';
                    return _p;
                  }
                  if (text == null ||text.length == 0) {
                    return '入力してください';
                  }
                  if (isEmail(text) || isUserName(text)) {
                    return null;
                  }
                  return '正しく入力してください';
                },
                onSaved: (text) {
                  if (text != null && text.startsWith('@')) {
                    text = text.substring(1);
                  }
                  this.userNameOrEmail = text ?? '';
                },
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Form(
              key: _keys[1],
              child: MyPasswordField(
                focusNode: _passwordFocusNode,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (text) {
                  _passwordFocusNode.unfocus();
                },
                validate: (text) {
                  if (passwordMessage.length > 0) {
                    String _p = passwordMessage;
                    passwordMessage = '';
                    return _p;
                  }
                  if (text == null ||text.length < 6) {
                    return '6文字以上入力してください';
                  }
                  return null;
                },
                onSaved: (text) {
                  this.password = text ?? '';
                },
                onChanged: (text) {
                  ref.read(_loginFormProvider.notifier).password = text.length > 5;
                },
              ),
            ),
            Container(
              width: double.infinity,
              alignment: Alignment.centerRight,
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context)
                      .textTheme
                      .subtitle1
                      ?.copyWith(fontSize: 12),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'パスワードを忘れた方は',
                    ),
                    TextSpan(
                        text: 'こちら',
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            ApplicationRoutes.pushReplacementNamed(
                                '/password-reset');
                          },
                        style: (TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          decoration: TextDecoration.underline,
                        ))),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 40,
            ),
            SignInButton(
              Buttons.Google,
              onPressed: () async {
                await signInWithGoogle(context);
              },
            ),
            SizedBox(
              height: 16,
            ),
            SignInButton(
              Buttons.Apple,
              onPressed: () async {
                await signInWithApple(context);
              },
            ),
            SizedBox(
              height: 24,
            ),
            Container(
              alignment: Alignment.center,
              margin: EdgeInsets.symmetric(vertical: 24),
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context)
                      .textTheme
                      .subtitle1
                      ?.copyWith(fontSize: 12),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'アカウントをお持ちでない方は',
                    ),
                    TextSpan(
                        text: '新規登録',
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            ApplicationRoutes.pushReplacementNamed('/register');
                          },
                        style: (TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          decoration: TextDecoration.underline,
                        ))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool isEmail(String? text) {
    if (text == null) return false;
    RegExp emailRegExp = new RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
      caseSensitive: false,
      multiLine: false,
    );
    return emailRegExp.hasMatch(text);
  }

  bool isUserName(String? text) {
    if (text == null) return false;
    RegExp userNameRegExp = new RegExp(
      r"^@?[a-zA-Z0-9_]+$",
      caseSensitive: false,
      multiLine: false,
    );
    return userNameRegExp.hasMatch(text);
  }

  Future<void> submit(BuildContext context) async {
    bool valid = true;
    for (GlobalKey<FormState> _key in _keys) {
      if (!(_key.currentState?.validate() ?? false)) {
        valid = false;
      }
    }
    if (valid) {
      for (GlobalKey<FormState> _key in _keys) {
        _key.currentState?.save();
      }
      String email;
      await MyLoading.startLoading();
      if (isUserName(userNameOrEmail)) {
        try {
          email = await AuthApi.getEmailAddress(userNameOrEmail);
        } on UserNotFoundException {
          passwordMessage = '';
          userNameOrEmailMessage = '登録されていないIDです';
          _keys[0].currentState?.validate();
          await MyLoading.dismiss();
          return;
        } on FirebaseNotFoundException {
          passwordMessage = '';
          userNameOrEmailMessage = '別の方法でのログインをお試しください';
          _keys[0].currentState?.validate();
          await MyLoading.dismiss();
          return;
        } catch (e) {
          await MyLoading.dismiss();
          MyErrorDialog.show(e);
          return;
        }
      } else {
        email = userNameOrEmail;
      }
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        if (!(userCredential.user?.emailVerified ?? false)) {
          await MyLoading.dismiss();
          Navigator.pushReplacementNamed(context, '/email-verify');
          return;
        }
        await ref.read(authProvider.notifier).login(email, password);
        await MyApp.initialize(ref);
        await MyLoading.dismiss();
        Navigator.popUntil(context, ModalRoute.withName('/title'));
        Navigator.of(context).pushReplacementNamed("/home");
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          passwordMessage = '';
          userNameOrEmailMessage = '登録されていません';
          _keys[0].currentState?.validate();
        } else if (e.code == 'wrong-password') {
          passwordMessage = 'パスワードが正しくありません';
          userNameOrEmailMessage = '';
          _keys[1].currentState?.validate();
        }
        await MyLoading.dismiss();
      } on UserNotFoundException {
        await MyLoading.dismiss();
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => NameInput()));
      } catch (e) {
        exit(1);
      }
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    await MyLoading.startLoading();
    try {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) throw Exception('google login failed');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      await userCredential.user?.reload();
      User? firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception('firebase user not found');
      await ref.read(authProvider.notifier).loginWithFirebase(firebaseUser);
      await MyApp.initialize(ref);
      MyLoading.dismiss();
      while (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      Navigator.pushReplacementNamed(context, '/home');
    } on UserNotFoundException {
      MyLoading.dismiss();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => NameInput()));
    } catch (e) {
      MyLoading.dismiss();
      MyErrorDialog.show(e, message: "ログインに失敗しました");
    }
  }


  Future<void> signInWithApple(BuildContext context) async {
    MyLoading.startLoading();
    try{
      // AuthorizationCredentialAppleIDのインスタンスを取得
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // OAthCredentialのインスタンスを作成
      OAuthProvider oauthProvider = OAuthProvider('apple.com');
      final credential = oauthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Once signed in, return the UserCredential
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      await userCredential.user?.reload();
      User? firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception('firebase user not found');
      await ref.read(authProvider.notifier).loginWithFirebase(firebaseUser);
      await MyApp.initialize(ref);
      await MyLoading.dismiss();
      while (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      Navigator.pushReplacementNamed(context, '/home');
    } on UserNotFoundException {
      await MyLoading.dismiss();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => NameInput()));
    } catch(e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e.toString());
    }
  }
}
