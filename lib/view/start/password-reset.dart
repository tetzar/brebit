import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../route/route.dart';
import '../general/loading.dart';
import '../widgets/app-bar.dart';
import '../widgets/dialog.dart';
import '../widgets/text-field.dart';

class PasswordReset extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(context: context, titleText: 'パスワードをリセット'),
      backgroundColor: Theme.of(context).primaryColor,
      body: PasswordInputForm(),
    );
  }
}

class PasswordInputForm extends StatefulWidget {
  @override
  _PasswordInputFormState createState() => _PasswordInputFormState();
}

class _PasswordInputFormState extends State<PasswordInputForm> {
  late GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  late FocusNode _focusNode;
  String email = '';
  String errorMessage = '';
  bool savable = false;

  bool isEmail(String text) {
    RegExp emailRegExp = new RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
      caseSensitive: false,
      multiLine: false,
    );
    return emailRegExp.hasMatch(text);
  }

  @override
  void initState() {
    savable = false;
    errorMessage = '';
    email = '';
    _focusNode = new FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _formKey.currentState?.validate();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MyBottomFixedButton(
      enable: savable,
      label: 'リセットリンクを送信',
      onTapped: () async {
        _focusNode.unfocus();
        await save();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            SizedBox(
              height: 24,
            ),
            Form(
              key: _formKey,
              child: MyTextField(
                label: 'メールアドレス',
                hintText: 'brebit@example.com',
                keyboardType: TextInputType.emailAddress,
                focusNode: _focusNode,
                onFieldSubmitted: (_) {
                  _focusNode.unfocus();
                },
                inputFormatter: [
                  FilteringTextInputFormatter.allow(RegExp(r"^[\x00-\x7F]+$"))
                ],
                textInputAction: TextInputAction.done,
                validate: (text) {
                  if (errorMessage.length > 0) {
                    String p = errorMessage;
                    errorMessage = '';
                    return p;
                  }
                  if (text == null || text.length == 0) {
                    return '入力してください';
                  }
                  return isEmail(text) ? null : '正しく入力してください';
                },
                onChanged: (text) {
                  email = text;
                  if (isEmail(text) != savable) {
                    setState(() {
                      savable = !savable;
                    });
                  }
                },
                onSaved: (text) {
                  this.email = text ?? '';
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> save() async {
    if ((_formKey.currentState?.validate() ?? false)) {
      _formKey.currentState?.save();
      try {
        MyLoading.startLoading();
        await _sendPasswordResetCode(email);
        await MyLoading.dismiss();
        ApplicationRoutes.pushReplacementNamed('/password-reset/sent',
            arguments: this.email);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          errorMessage = 'アカウントが存在しません';
          _formKey.currentState?.validate();
          await MyLoading.dismiss();
          return;
        }
        await MyLoading.dismiss();
        MyErrorDialog.show(e);
      } catch (e) {
        await MyLoading.dismiss();
        MyErrorDialog.show(e);
      }
    }
  }
}

Future<void> _sendPasswordResetCode(String email) async {
  var actionCodeSettings = ActionCodeSettings(
    url: 'https://brebit.dev/password-reset/form/?email=$email',
    androidPackageName: "dev.brebit",
    dynamicLinkDomain: 'brebit.page.link',
    androidInstallApp: true,
    iOSBundleId: "dev.brebit",
    handleCodeInApp: true,
  );
  MyLoading.startLoading();
  await FirebaseAuth.instance.sendPasswordResetEmail(
      email: email, actionCodeSettings: actionCodeSettings);
  await MyLoading.dismiss();
}

class PasswordResetSend extends StatelessWidget {
  final String email;

  PasswordResetSend(this.email);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(
        context: context,
        titleText: 'パスワードをリセット',
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 64,
            ),
            Text(
              'リセットリンクを\n送信しました',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 24,
            ),
            Text(
              '“$email”宛に\nパスワードのリセットリンクを記載して\nメールを送信しました。',
              style:
                  Theme.of(context).textTheme.bodyText1?.copyWith(fontSize: 17),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 64,
            ),
            InkWell(
              onTap: () async {
                try {
                  MyLoading.startLoading();
                  await _sendPasswordResetCode(email);
                  await MyLoading.dismiss();
                } catch (e) {
                  await MyLoading.dismiss();
                  MyErrorDialog.show(e);
                }
              },
              borderRadius: BorderRadius.circular(17),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 144,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Text(
                      'メールを再送する',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class PasswordResetForm extends StatelessWidget {
  final PendingDynamicLinkData dynamicLink;

  PasswordResetForm(this.dynamicLink);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(
          context: context,
          backButton: AppBarBackButton.none,
          titleText: 'パスワードをリセット'),
      backgroundColor: Theme.of(context).primaryColor,
      body: PasswordResetFormContent(dynamicLink),
    );
  }
}

class PasswordResetFormContent extends StatefulWidget {
  final PendingDynamicLinkData dynamicLink;

  PasswordResetFormContent(this.dynamicLink);

  @override
  _PasswordResetFormContentState createState() =>
      _PasswordResetFormContentState();
}

class _PasswordResetFormContentState extends State<PasswordResetFormContent> {
  String password = '';
  String errorMessage = '';
  late FocusNode _focusNode;
  late GlobalKey<FormState> _formKey;
  bool savable = false;

  @override
  void initState() {
    password = '';
    errorMessage = '';
    savable = false;
    _formKey = new GlobalKey<FormState>();
    _focusNode = new FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _formKey.currentState?.validate();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MyBottomFixedButton(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
            ),
            Form(
              key: _formKey,
              child: MyPasswordField(
                validate: (text) {
                  if (errorMessage.length > 0) {
                    String p = errorMessage;
                    errorMessage = '';
                    return p;
                  }
                  if (text == null || text.length == 0) {
                    return '入力してください';
                  }
                  return text.length > 5 ? null : '６文字以上入力してください';
                },
                onChanged: (text) {
                  this.password = text;
                  if (password.length > 5 != savable) {
                    setState(() {
                      savable = !savable;
                    });
                  }
                },
                focusNode: _focusNode,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  _focusNode.unfocus();
                },
                onSaved: (text) {
                  this.password = text ?? '';
                },
              ),
            )
          ],
        ),
      ),
      label: '保存',
      enable: savable,
      onTapped: () async {
        _focusNode.unfocus();
        try {
          await save();
          String? url = widget.dynamicLink.link.queryParameters['continueUrl'];
          if (url == null) throw Exception('Cannot fetch url');
          Uri _uri = Uri.parse(url);
          ApplicationRoutes.pushReplacementNamed('/login',
              arguments: _uri.queryParameters['email']);
        } catch (e) {
          ApplicationRoutes.pushReplacementNamed('/title');
          MyErrorDialog.show(e);
        }
      },
    );
  }

  Future<void> save() async {
    MyLoading.startLoading();
    try {
      String? oobCode = widget.dynamicLink.link.queryParameters['oobCode'];
      if (oobCode == null) throw Exception('oobCode is null');
      await FirebaseAuth.instance
          .confirmPasswordReset(code: oobCode, newPassword: this.password);
    } catch (e) {
      MyErrorDialog.show(e);
    }
    MyLoading.dismiss();
  }
}
