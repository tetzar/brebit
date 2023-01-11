import 'dart:async';

import 'package:brebit/view/widgets/text-field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../provider/auth.dart';
import '../../../../route/route.dart';
import '../../general/loading.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/back-button.dart';
import '../../widgets/dialog.dart';

class EmailSetting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!AuthProvider.getProviders().contains(CredentialProviders.password)) {
      return Scaffold(
        appBar: getMyAppBar(
            context: context,
            backButton: AppBarBackButton.none,
            actions: [MyBackButtonX()]),
        body: RegisterEmail(),
        backgroundColor: Theme.of(context).primaryColor,
      );
    }
    return Scaffold(
      appBar: getMyAppBar(
          context: context,
          backButton: AppBarBackButton.none,
          titleText: '',
          actions: [MyBackButtonX()]),
      backgroundColor: Theme.of(context).primaryColor,
      body: ChangeEmail(),
    );
  }
}

class RegisterEmailProviderState {
  bool? email;
  bool? password;
  RegisterEmailProviderState({this.email = false, this.password = false});
}

class RegisterEmailProvider extends StateNotifier<RegisterEmailProviderState> {
  RegisterEmailProvider(RegisterEmailProviderState state) : super(state);

  bool get email {
    return state.email ?? false;
  }

  bool get password {
    return state.password ?? false;
  }

  void set(bool? email, bool? password) {
    var newState = RegisterEmailProviderState(
      email: email ?? state.email,
        password: password ?? state.password
    );
    state = newState;
  }

  set email(bool s) {
    if (s != email) {
      set(s, null);
    }
  }

  set password(bool s) {
    if (s != password) {
      set(null, s);
    }
  }

  bool savable() {
    return email && password;
  }
}

final _registerEmailProvider = StateNotifierProvider.autoDispose(
    (ref) => RegisterEmailProvider(RegisterEmailProviderState()));

class RegisterEmail extends ConsumerStatefulWidget {
  @override
  _RegisterEmailState createState() => _RegisterEmailState();
}

class _RegisterEmailState extends ConsumerState<RegisterEmail> {
  late List<GlobalKey<FormState>> _keys;
  String email = '';
  String password = '';

  late FocusNode _emailFocusNode;
  late FocusNode _passwordFocusNode;

  String? emailErrorMessage;
  String? passwordErrorMessage;

  @override
  void initState() {
    email = '';
    password = '';
    _keys = [
      GlobalKey<FormState>(),
      GlobalKey<FormState>(),
    ];
    _emailFocusNode = new FocusNode();
    _passwordFocusNode = new FocusNode();

    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _keys[0].currentState?.validate();
      }
    });
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        _keys[1].currentState?.validate();
      }
    });
    super.initState();
  }

  bool isEmail(String text) {
    RegExp emailRegExp = new RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
      caseSensitive: false,
      multiLine: false,
    );
    return emailRegExp.hasMatch(text);
  }

  bool savable() {
    if (password.length < 5) {
      return false;
    }
    return isEmail(email);
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MyHookBottomFixedButton(
      provider: _registerEmailProvider,
      onTapped: () async {
        _emailFocusNode.unfocus();
        _passwordFocusNode.unfocus();
        await save();
      },
      label: '登録する',
      enable: () {
        return ref.read(_registerEmailProvider.notifier).savable();
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 64, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'メールアドレスを登録',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(fontWeight: FontWeight.w700, fontSize: 20),
            ),
            SizedBox(
              height: 24,
            ),
            Text(
              'メールアドレスによる\nログインが可能になります。',
              textAlign: TextAlign.center,
              style:
                  Theme.of(context).textTheme.bodyText1?.copyWith(fontSize: 15),
            ),
            SizedBox(
              height: 40,
            ),
            Form(
              key: _keys[0],
              child: MyTextField(
                focusNode: _emailFocusNode,
                textInputAction: TextInputAction.next,
                inputFormatter: [
                  FilteringTextInputFormatter.allow(RegExp(r"^[\x00-\x7F]+$"))
                ],
                keyboardType: TextInputType.emailAddress,
                onFieldSubmitted: (_) {
                  _emailFocusNode.unfocus();
                  _passwordFocusNode.requestFocus();
                },
                validate: (text) {
                  if (text == null || text.isEmpty) {
                    return '入力してください';
                  }
                  return isEmail(text) ? null : '正しく入力してください';
                },
                label: 'メールアドレス',
                hintText: 'brebit@example.com',
                onChanged: (String text) {
                  if (text.length == 0) {
                    ref.read(_registerEmailProvider.notifier).email = false;
                  }
                  ref.read(_registerEmailProvider.notifier).email =
                      isEmail(text);
                },
                onSaved: (String? text) {
                  this.email = text ?? '';
                },
              ),
            ),
            SizedBox(
              height: 16,
            ),
            Form(
              key: _keys[1],
              child: MyPasswordField(
                focusNode: _passwordFocusNode,
                onFieldSubmitted: (_) {
                  _passwordFocusNode.unfocus();
                },
                textInputAction: TextInputAction.done,
                validate: (text) {
                  if (text == null || text.length < 6) {
                    return '6文字以上入力してください';
                  }
                  return null;
                },
                onChanged: (text) {
                  ref.read(_registerEmailProvider.notifier).password =
                      text.length > 5;
                },
                onSaved: (text) {
                  this.password = text ?? '';
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> save() async {
    bool valid = true;
    print("save");
    for (GlobalKey<FormState> _key in _keys) {
      if (!(_key.currentState?.validate() ?? false)) {
        valid = false;
      }
    }
    if (valid) {
      for (GlobalKey<FormState> _key in _keys) {
        _key.currentState?.save();
      }
      try {
        MyLoading.startLoading();
        print(this.email);
        print(this.password);
        AuthCredential credential =
            EmailAuthProvider.credential(email: email, password: password);
        User? firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser == null) return;
        await firebaseUser.linkWithCredential(credential);
        await firebaseUser.reload();
        if (!firebaseUser.emailVerified) {
          var actionCodeSettings = ActionCodeSettings(
            url: 'https://brebit.dev/email-set',
            androidPackageName: "dev.brebit",
            dynamicLinkDomain: 'brebit.page.link',
            androidInstallApp: true,
            iOSBundleId: "dev.brebit",
            handleCodeInApp: true,
          );
          await firebaseUser.sendEmailVerification(actionCodeSettings);
        }
        await MyLoading.dismiss();
        ApplicationRoutes.pushReplacementNamed(
            '/settings/account/email/register/complete',
            arguments: email);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          await MyLoading.dismiss();
          showDialog(
              context: ApplicationRoutes.materialKey.currentContext ?? context,
              builder: (context) {
                return MyDialog(
                  title: Text(
                    '既に登録済みの\nメールアドレスです',
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  body: SizedBox(
                    height: 0,
                  ),
                  actionText: 'OK',
                  action: () {
                    ApplicationRoutes.pop();
                  },
                  onlyAction: true,
                );
              });
        } else {
          await MyLoading.dismiss();
          MyErrorDialog.show(e);
        }
      } catch (e) {
        await MyLoading.dismiss();
        MyErrorDialog.show(e);
      }
    }
  }
}

class EmailRegisterComplete extends StatelessWidget {
  final String email;

  EmailRegisterComplete(this.email);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(
          context: context,
          titleText: '',
          backButton: AppBarBackButton.none,
          actions: [MyBackButtonX()]),
      body: Container(
        height: double.infinity,
        color: Theme.of(context).primaryColor,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'メールアドレスを登録しました。',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(
              height: 24,
            ),
            Text(
              'メールアドレス${this.email}\nを登録しました。',
              style:
                  Theme.of(context).textTheme.bodyText1?.copyWith(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 24,
            ),
            Text(
              '${this.email}宛に届いた\nメールのリンクを開くと、\nログインが可能になります。',
              style:
                  Theme.of(context).textTheme.bodyText1?.copyWith(fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SavableProviderState {
  bool email;
  bool password;

  _SavableProviderState(this.email, this.password);
}

class _SavableProvider extends StateNotifier<_SavableProviderState> {
  _SavableProvider(_SavableProviderState state) : super(state);

  void set(bool? email, bool? password) {
    _SavableProviderState newState =
    new _SavableProviderState(email ?? state.email
        , password ?? state.password);
    this.state = newState;
  }

  void setEmail(bool s) {
    if (this.state.email != s) {
      set(s, null);
    }
  }

  void setPassword(bool s) {
    if (this.state.password != s) {
      set(null, s);
    }
  }

  bool savable() {
    return this.state.password && this.state.email;
  }
}

final _savableProvider = StateNotifierProvider.autoDispose(
    (ref) => _SavableProvider(_SavableProviderState(false, false)));

class ChangeEmail extends ConsumerStatefulWidget {
  @override
  _ChangeEmailState createState() => _ChangeEmailState();
}

class _ChangeEmailState extends ConsumerState<ChangeEmail> {
  late GlobalKey<FormState> _emailKey;
  late GlobalKey<FormState> _passwordKey;
  String email = '';
  String password = '';
  late FocusNode _emailFocusNode;
  late FocusNode _passwordFocusNode;

  String emailErrorMessage = '';
  String passwordErrorMessage = '';

  @override
  void initState() {
    email = '';
    password = '';
    _passwordKey = GlobalKey<FormState>();
    _emailKey = GlobalKey<FormState>();
    _passwordFocusNode = new FocusNode();
    _emailFocusNode = new FocusNode();
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _emailKey.currentState?.validate();
      }
    });
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        _passwordKey.currentState?.validate();
      }
    });
    super.initState();
  }

  bool isEmail(String text) {
    RegExp emailRegExp = new RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
      caseSensitive: false,
      multiLine: false,
    );
    return emailRegExp.hasMatch(text);
  }

  Future<void> save() async {
    if ((_emailKey.currentState?.validate() ?? false) &&
        (_passwordKey.currentState?.validate() ?? false)) {
      _emailKey.currentState!.save();
      _passwordKey.currentState!.save();
      try {
        MyLoading.startLoading();
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        User? firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser == null) return;
        await firebaseUser.reload();
        await firebaseUser.updateEmail(email);
        await firebaseUser.reload();
        if (!firebaseUser.emailVerified) {
          var actionCodeSettings = ActionCodeSettings(
            url: 'https://brebit.dev/email-set',
            androidPackageName: "dev.brebit",
            dynamicLinkDomain: 'brebit.page.link',
            androidInstallApp: true,
            iOSBundleId: "dev.brebit",
            handleCodeInApp: true,
          );
          await firebaseUser.sendEmailVerification(actionCodeSettings);
        }
        await MyLoading.dismiss();
        ApplicationRoutes.pushReplacementNamed(
            '/settings/account/email/change/complete',
            arguments: email);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          await MyLoading.dismiss();
          showDialog(
              context: ApplicationRoutes.materialKey.currentContext ?? context,
              builder: (context) {
                return MyDialog(
                  title: Text(
                    '既に登録済みの\nメールアドレスです',
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  body: SizedBox(
                    height: 0,
                  ),
                  actionText: 'OK',
                  action: () {
                    ApplicationRoutes.pop();
                  },
                  onlyAction: true,
                );
              });
        } else if (e.code == 'wrong-password') {
          passwordErrorMessage = 'パスワードが正しくありません';
          _passwordKey.currentState?.validate();
          await MyLoading.dismiss();
        } else {
          await MyLoading.dismiss();
          MyErrorDialog.show(e);
        }
      } catch (e) {
        await MyLoading.dismiss();
        MyErrorDialog.show(e);
      }
    }
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? currentEmail = FirebaseAuth.instance.currentUser?.email;
    return MyHookBottomFixedButton(
      provider: _savableProvider,
      onTapped: () async {
        _emailFocusNode.unfocus();
        _passwordFocusNode.unfocus();
        await save();
      },
      label: '変更する',
      enable: () {
        return ref.read(_savableProvider.notifier).savable();
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 64, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'メールアドレスを変更',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(fontWeight: FontWeight.w700, fontSize: 20),
            ),
            SizedBox(
              height: 24,
            ),
            Text(
              '現在のメールアドレス: \n$currentEmail',
              textAlign: TextAlign.center,
              style:
                  Theme.of(context).textTheme.bodyText1?.copyWith(fontSize: 15),
            ),
            SizedBox(
              height: 40,
            ),
            Form(
              key: _emailKey,
              child: MyTextField(
                validate: (text) {
                  if (text == null || text.length == 0) {
                    return '入力してください';
                  }
                  return isEmail(text) ? null : '正しく入力してください';
                },
                onFieldSubmitted: (_) {
                  _emailFocusNode.unfocus();
                  _passwordFocusNode.requestFocus();
                },
                focusNode: _emailFocusNode,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.emailAddress,
                inputFormatter: [
                  FilteringTextInputFormatter.allow(RegExp(r"^[\x00-\x7F]+$"))
                ],
                label: '新しいメールアドレス',
                hintText: 'brebit@example.com',
                onChanged: (String text) {
                  this.email = text;
                  ref.read(_savableProvider.notifier).setEmail(isEmail(text));
                },
                onSaved: (String? text) {
                  this.email = text ?? '';
                },
              ),
            ),
            SizedBox(
              height: 16,
            ),
            Form(
                key: _passwordKey,
                child: MyPasswordField(
                  focusNode: _passwordFocusNode,
                  onFieldSubmitted: (_) {
                    _passwordFocusNode.unfocus();
                  },
                  textInputAction: TextInputAction.done,
                  label: '現在のパスワード',
                  validate: (text) {
                    if (passwordErrorMessage.length > 0) {
                      String p = passwordErrorMessage;
                      passwordErrorMessage = '';
                      return p;
                    }
                    if (text == null || text.length == 0) {
                      return '入力してください';
                    }
                    return text.length < 6 ? '６文字以上入力してください' : null;
                  },
                  onChanged: (text) {
                    ref
                        .read(_savableProvider.notifier)
                        .setPassword(text.length > 5);
                  },
                  onSaved: (text) {
                    this.password = text ?? '';
                  },
                ))
          ],
        ),
      ),
    );
  }
}

class EmailChangeComplete extends StatelessWidget {
  final String email;

  EmailChangeComplete(this.email);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(
          context: context,
          titleText: '',
          backButton: AppBarBackButton.none,
          actions: [MyBackButtonX()]),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        color: Theme.of(context).primaryColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'メールアドレスを変更しました。',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(
              height: 24,
            ),
            Text(
              'メールアドレスを\n${this.email}に変更しました。',
              style:
                  Theme.of(context).textTheme.bodyText1?.copyWith(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 24,
            ),
            Text(
              '${this.email}宛に届いた\nメールのリンクを開くと、\nログインが可能になります。',
              style:
                  Theme.of(context).textTheme.bodyText1?.copyWith(fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
