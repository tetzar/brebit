// package:brebit/view/regiter.dart

import 'dart:async';

import 'package:brebit/auth/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../library/cache.dart';
import '../../../library/exceptions.dart';
import '../../../provider/auth.dart';
import '../../../route/route.dart';
import '../../main.dart';
import '../general/loading.dart';
import '../widgets/app-bar.dart';
import '../widgets/dialog.dart';
import '../widgets/text-field.dart';
import 'name-form.dart';

class RegisterProviderState {
  bool? nickName;
  bool? email;
  bool? password;
  bool? userName;
}

class RegisterProvider extends StateNotifier<RegisterProviderState> {
  RegisterProvider(RegisterProviderState state) : super(state);

  void set(
      {bool? emailValid,
      bool? nickNameValid,
      bool? userNameValid,
      bool? passwordValid}) {
    RegisterProviderState newState = new RegisterProviderState();
    newState.email = emailValid ?? state.email;
    newState.nickName = nickNameValid ?? state.nickName;
    newState.userName = userNameValid ?? state.userName;
    newState.password = passwordValid ?? state.password;
    state = newState;
  }

  get nickName {
    return this.state.nickName ?? false;
  }

  get email {
    return this.state.email ?? false;
  }

  get password {
    return this.state.password ?? false;
  }

  get userName {
    return this.state.userName ?? false;
  }

  void changedNickName(String text) {
    if (this.nickName) {
      if (text.length == 0) {
        set(nickNameValid: false);
      }
    } else {
      if (text.length > 0) {
        set(nickNameValid: true);
      }
    }
  }

  void setUserName(bool s) {
    if (s != this.userName) {
      set(userNameValid: s);
    }
  }

  bool setEmail(bool s) {
    if (s != this.email) {
      set(emailValid: s);
      return true;
    }
    return false;
  }

  void setPassword(bool s) {
    if (s != this.password) {
      set(passwordValid: s);
    }
  }

  bool savable() {
    return (this.password ?? false) &&
        (this.email ?? false) &&
        (this.userName ?? false) &&
        (this.nickName ?? false);
  }
}

final _registerProvider = StateNotifierProvider.autoDispose(
    (ref) => RegisterProvider(new RegisterProviderState()));

class Registration extends StatelessWidget {
  final Map<String, String>? registrationInitialData;

  Registration(this.registrationInitialData);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(context: context, titleText: '新規登録'),
      body: RegistrationForm(registrationInitialData),
      backgroundColor: Theme.of(context).primaryColor,
    );
  }
}

class RegistrationForm extends ConsumerStatefulWidget {
  final Map<String, String>? registrationInitialData;

  RegistrationForm(this.registrationInitialData);

  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends ConsumerState<RegistrationForm> {
  late List<GlobalKey<FormState>> _keys;
  late Map<String, String> inputData;

  late Map<String, String> initialData;

  late FocusNode _nickNameFocusNode;
  late FocusNode _userNameFocusNode;
  late FocusNode _emailFocusNode;
  late FocusNode _passwordFocusNode;

  bool emailInUse = false;

  bool firstBuild = false;

  @override
  void initState() {
    initialData = widget.registrationInitialData ??
        {
          'nickName': '',
          'userName': '',
          'email': '',
        };
    _keys = [
      new GlobalKey<FormState>(),
      new GlobalKey<FormState>(),
      new GlobalKey<FormState>(),
      new GlobalKey<FormState>(),
    ];
    _userNameFocusNode = new FocusNode();
    _nickNameFocusNode = new FocusNode();
    _emailFocusNode = new FocusNode();
    _passwordFocusNode = new FocusNode();
    _nickNameFocusNode.addListener(() {
      if (!_nickNameFocusNode.hasFocus) {
        _keys[0].currentState?.validate();
      }
    });
    _userNameFocusNode.addListener(() {
      if (!_userNameFocusNode.hasFocus) {
        _keys[1].currentState?.validate();
      }
    });
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _keys[2].currentState?.validate();
      }
    });
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        _keys[3].currentState?.validate();
      }
    });
    inputData = {
      'nickName': '',
      'userName': '',
      'email': '',
      'password': '',
    };
    emailInUse = false;
    if (widget.registrationInitialData != null) {
      ref.read(_registerProvider.notifier).set(
            nickNameValid: initialData['nickName']!.length > 0,
            emailValid: isEmail(initialData['email']!),
          );
    }
    super.initState();
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _userNameFocusNode.dispose();
    _nickNameFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MyHookFlexibleLabelBottomFixedButton(
      provider: _registerProvider,
      labelChange: () {
        return emailInUse ? 'サインイン' : '新規登録';
      },
      enable: () {
        return ref.read(_registerProvider.notifier).savable();
      },
      onTapped: () async {
        _userNameFocusNode.unfocus();
        _nickNameFocusNode.unfocus();
        _passwordFocusNode.unfocus();
        _emailFocusNode.unfocus();
        if (emailInUse) {
          ApplicationRoutes.pushReplacementNamed('/login',
              arguments: inputData['email']);
        } else {
          await submit(context);
        }
      },
      child: Container(
        padding: EdgeInsets.only(
          top: 32,
          right: 24,
          left: 24,
        ),
        child: Column(
          children: [
            Column(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Form(
                    key: _keys[0],
                    child: MyTextField(
                        onFieldSubmitted: (_) {
                          _nickNameFocusNode.unfocus();
                          _userNameFocusNode.requestFocus();
                        },
                        textInputAction: TextInputAction.next,
                        focusNode: _nickNameFocusNode,
                        label: 'ニックネーム',
                        validate: (String? text) {
                          if (text == null || text.length == 0) {
                            return '入力してください';
                          }
                          return null;
                        },
                        onSaved: (text) {
                          inputData['nickName'] = text ?? '';
                        },
                        onChanged: (text) {
                          ref
                              .read(_registerProvider.notifier)
                              .changedNickName(text);
                        },
                        hintText: 'やまだ　たろう',
                        initialValue: initialData['nickName']),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Form(
                    key: _keys[1],
                    child: MyUserNameField(
                      onFieldSubmitted: (_) {
                        _userNameFocusNode.unfocus();
                        _emailFocusNode.requestFocus();
                      },
                      textInputAction: TextInputAction.next,
                      focusNode: _userNameFocusNode,
                      initialValue: initialData['userName'] ?? '',
                      initialCheck: true,
                      onStateChange: (state) {
                        ref
                            .read(_registerProvider.notifier)
                            .setUserName(state == CustomIdFieldState.allowed);
                        _keys[1].currentState?.validate();
                      },
                      onValidate: (_) {},
                      onSaved: (text) async {
                        inputData['userName'] = text ?? '';
                      },
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Form(
                    key: _keys[2],
                    child: MyTextField(
                        label: 'メールアドレス',
                        keyboardType: TextInputType.emailAddress,
                        onFieldSubmitted: (_) {
                          _emailFocusNode.unfocus();
                          _passwordFocusNode.requestFocus();
                        },
                        onHintValidate: (text) {
                          return emailInUse ? '既に登録済みです' : null;
                        },
                        textInputAction: TextInputAction.next,
                        focusNode: _emailFocusNode,
                        onChanged: (text) {
                          bool built = ref
                              .read(_registerProvider.notifier)
                              .setEmail(isEmail(text));
                          if (!built && emailInUse) {
                            emailInUse = false;
                            ref.read(_registerProvider.notifier).set();
                          }
                          emailInUse = false;
                        },
                        validate: (String? text) {
                          return isEmail(text) ? null : '正しく入力してください';
                        },
                        onSaved: (text) {
                          inputData['email'] = text ?? '';
                        },
                        hintText: 'brebit@example.com',
                        initialValue: initialData['email']),
                  ),
                ),
                Container(
                    margin: EdgeInsets.only(bottom: 8),
                    child: Form(
                      key: _keys[3],
                      child: MyPasswordField(
                        focusNode: _passwordFocusNode,
                        onFieldSubmitted: (_) {
                          _passwordFocusNode.unfocus();
                        },
                        textInputAction: TextInputAction.done,
                        onChanged: (text) {
                          ref
                              .read(_registerProvider.notifier)
                              .setPassword(text.length > 5);
                        },
                        onSaved: (text) {
                          inputData['password'] = text ?? '';
                        },
                        validate: (text) {
                          if (text == null || text.length < 6) {
                            return '6文字以上入力してください';
                          }
                          return null;
                        },
                      ),
                    )),
              ],
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Text('または'),
            ),
            Column(children: [
              SignInButton(
                Buttons.Google,
                text: "Sign up with Google",
                onPressed: () async {
                  await signInWithGoogle(context);
                },
              ),
              SizedBox(
                height: 16,
              ),
              SignInButtonBuilder(
                icon: Icons.apple,
                text: "Sign up with Apple",
                onPressed: () async {
                  await signInWithApple(context);
                },
                backgroundColor: Colors.black,
              ),
            ]),
            Container(
              margin: EdgeInsets.symmetric(vertical: 24),
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context)
                      .textTheme
                      .subtitle1
                      ?.copyWith(fontSize: 12),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'アカウントをお持ちの方は',
                    ),
                    TextSpan(
                        text: 'サインイン',
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            ApplicationRoutes.pushReplacementNamed('/login');
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

  Future<void> submit(BuildContext ctx) async {
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
      MyLoading.startLoading();
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: inputData['email']!, password: inputData['password']!);
        User? firebaseUser = userCredential.user;
        if (firebaseUser == null) throw Exception('firebase user not found');
        if (firebaseUser.emailVerified) {
          try {
            await MyApp.initialize(ref);
          } on UserNotFoundException {
            await MyLoading.dismiss();
            while (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => NameInput()));
          } catch (e) {
            await MyLoading.dismiss();
            while (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            Navigator.pushReplacementNamed(context, '/title');
          }
        } else {
          await LocalManager.setRegisterInformation(
              firebaseUser,
              inputData['email']!,
              inputData['userName']!,
              inputData['nickName']!);
          await MyLoading.dismiss();
          Navigator.pushReplacementNamed(context, '/email-verify',
              arguments: inputData['nickName']);
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          UserCredential userCredential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(
                  email: inputData['email']!, password: inputData['password']!);
          User? firebaseUser = userCredential.user;
          if (firebaseUser != null && !firebaseUser.emailVerified) {
            await LocalManager.setRegisterInformation(
                firebaseUser,
                inputData['email']!,
                inputData['userName']!,
                inputData['nickName']!);
            await MyLoading.dismiss();
            Navigator.pushReplacementNamed(context, '/email-verify',
                arguments: inputData['nickName']);
            return;
          }
          emailInUse = true;
          ref.read(_registerProvider.notifier).set();
          _keys[2].currentState?.validate();
        } else {
          print(e);
        }
        await MyLoading.dismiss();
      } catch (e) {
        await MyLoading.dismiss();
        MyErrorDialog.show(e);
      }
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    await socialSignIn(context, CredentialProviders.google);
  }

  Future<void> signInWithApple(BuildContext context) async {
    await socialSignIn(context, CredentialProviders.apple);
  }

  Future<void> socialSignIn(
      BuildContext context, CredentialProviders provider) async {
    await MyLoading.startLoading();
    try {
      await Authorization.socialSignIn(provider, ref);
      await MyApp.initialize(ref);
      MyLoading.dismiss();
      while (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      MyLoading.dismiss();
      MyErrorDialog.show(e, message: "ログインに失敗しました");
    }
  }
}
