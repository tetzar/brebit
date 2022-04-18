// package:brebit/view/regiter.dart

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  bool nickName;
  bool email;
  bool password;
  bool userName;
}

class RegisterProvider extends StateNotifier<RegisterProviderState> {
  RegisterProvider(RegisterProviderState state) : super(state);

  void set(
      {bool emailValid,
      bool nickNameValid,
      bool userNameValid,
      bool passwordValid}) {
    RegisterProviderState newState = new RegisterProviderState();
    newState.email = emailValid ?? false;
    newState.nickName = nickNameValid ?? false;
    newState.userName = userNameValid ?? false;
    newState.password = passwordValid ?? false;
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
        state = state..nickName = false;
      }
    } else {
      if (text.length > 0) {
        state = state..nickName = true;
      }
    }
  }

  void setUserName(bool s) {
    if (s != this.userName) {
      state = state..userName = s;
    }
  }

  bool setEmail(bool s) {
    if (s != this.email) {
      state = state..email = s;
      return true;
    }
    return false;
  }

  void setPassword(bool s) {
    if (s != this.password) {
      state = state..password = s;
    }
  }

  void build() {
    state = state;
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
  final Map<String, String> registrationInitialData;

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

class RegistrationForm extends StatefulWidget {
  final Map<String, String> registrationInitialData;

  RegistrationForm(this.registrationInitialData);

  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  List<GlobalKey<FormState>> _keys;
  Map<String, String> inputData;

  Map<String, String> initialData;

  FocusNode _nickNameFocusNode;
  FocusNode _userNameFocusNode;
  FocusNode _emailFocusNode;
  FocusNode _passwordFocusNode;

  bool emailInUse;

  bool firstBuild;

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
        _keys[0].currentState.validate();
      }
    });
    _userNameFocusNode.addListener(() {
      if (!_userNameFocusNode.hasFocus) {
        _keys[1].currentState.validate();
      }
    });
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _keys[2].currentState.validate();
      }
    });
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        _keys[3].currentState.validate();
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
      context.read(_registerProvider).set(
            nickNameValid: initialData['nickName'].length > 0,
            emailValid: isEmail(initialData['email']),
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
        return context.read(_registerProvider).savable();
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
                        validate: (String text) {
                          if (text.length == 0) {
                            return '入力してください';
                          }
                          return null;
                        },
                        onSaved: (text) {
                          inputData['nickName'] = text;
                        },
                        onChanged: (text) {
                          context.read(_registerProvider).changedNickName(text);
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
                      initialValue: initialData['userName'],
                      initialCheck: true,
                      onStateChange: (state) {
                        context
                            .read(_registerProvider)
                            .setUserName(state == CustomIdFieldState.allowed);
                        _keys[1].currentState.validate();
                      },
                      onValidate: (_) {},
                      onSaved: (text) async {
                        inputData['userName'] = text;
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
                          bool built = context
                              .read(_registerProvider)
                              .setEmail(isEmail(text));
                          if (!built && emailInUse) {
                            emailInUse = false;
                            context.read(_registerProvider).build();
                          }
                          emailInUse = false;
                        },
                        validate: (String text) {
                          return isEmail(text) ? null : '正しく入力してください';
                        },
                        onSaved: (text) {
                          inputData['email'] = text;
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
                          context
                              .read(_registerProvider)
                              .setPassword(text.length > 5);
                        },
                        onSaved: (text) {
                          inputData['password'] = text;
                        },
                        validate: (text) {
                          if (text.length < 6) {
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
              InkWell(
                onTap: () async {
                  await signInWithGoogle(context);
                },
                child: SvgPicture.asset('assets/images/googleSignInButton.svg'),
              ),
              SizedBox(
                height: 16,
              ),
              InkWell(
                onTap: () async {
                  await signInWithApple();
                },
                child: Image.asset('assets/images/appleSignInButton.png'),
              ),
            ]),
            Container(
              margin: EdgeInsets.symmetric(vertical: 24),
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context)
                      .textTheme
                      .subtitle1
                      .copyWith(fontSize: 12),
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
                          color: Theme.of(context).accentColor,
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

  bool isEmail(String text) {
    RegExp emailRegExp = new RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
      caseSensitive: false,
      multiLine: false,
    );
    return emailRegExp.hasMatch(text);
  }

  bool isUserName(String text) {
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
      if (!_key.currentState.validate()) {
        valid = false;
      }
    }
    if (valid) {
      for (GlobalKey<FormState> _key in _keys) {
        _key.currentState.save();
      }
      MyLoading.startLoading();
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: inputData['email'], password: inputData['password']);
        if (userCredential.user.emailVerified) {
          try {
            await MyApp.initialize(ctx);
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
          await LocalManager.setRegisterInformation(userCredential.user,
              inputData['email'], inputData['userName'], inputData['nickName']);
          await MyLoading.dismiss();
          Navigator.pushReplacementNamed(context, '/email-verify',
              arguments: inputData['nickName']);
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          emailInUse = true;
          ctx.read(_registerProvider).build();
          _keys[2].currentState.validate();
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
    MyLoading.startLoading();
    try {
      final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return;
      }
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final GoogleAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      await context.read(authProvider).loginWithFirebase(userCredential.user);
      await MyApp.initialize(context);
      await MyLoading.dismiss();
      while (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      Navigator.pushReplacementNamed(context, '/home');
    } on UserNotFoundException {
      await MyLoading.dismiss();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => NameInput()));
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }

  Future<void> signInWithApple() async {}
}
