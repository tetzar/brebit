import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../route/route.dart';
import '../../general/loading.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/back-button.dart';
import '../../widgets/dialog.dart';
import '../../widgets/text-field.dart';

class ChangePassword extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(
          context: context,
          backButton: AppBarBackButton.none,
          titleText: '',
          actions: [MyBackButtonX()]),
      body: ChangePasswordForm(),
      backgroundColor: Theme.of(context).primaryColor,
    );
  }
}

class _SavableProviderState {
  bool currentPassword;
  bool newPassword;

  _SavableProviderState(this.currentPassword, this.newPassword);
}

class _SavableProvider extends StateNotifier<_SavableProviderState> {
  _SavableProvider(_SavableProviderState state) : super(state);

  void set(bool? currentPassword, bool? newPassword) {
    _SavableProviderState newState =
    new _SavableProviderState(currentPassword ?? state.currentPassword,
        newPassword ?? state.newPassword);
    this.state = newState;
  }

  void setNewPassword(bool s) {
    if (this.state.newPassword != s) {
      set(null, s);
    }
  }

  void setCurrentPassword(bool s) {
    if (this.state.currentPassword != s) {
      set(s, null);
    }
  }

  bool savable() {
    return this.state.currentPassword && this.state.newPassword;
  }
}

final _savableProvider = StateNotifierProvider.autoDispose(
    (ref) => _SavableProvider(_SavableProviderState(false, false)));

class ChangePasswordForm extends ConsumerStatefulWidget {
  @override
  _ChangePasswordFormState createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<ChangePasswordForm> {
  late GlobalKey<FormState> _newPasswordKey;
  late GlobalKey<FormState> _currentPasswordKey;
  late FocusNode _newPasswordFocusNode;
  late FocusNode _currentPasswordFocusNode;
  String newPassword = '';
  String currentPassword = '';

  String newPasswordErrorMessage = '';
  String currentPasswordErrorMessage = '';

  @override
  void initState() {
    newPassword = '';
    currentPassword = '';
    newPasswordErrorMessage = '';
    currentPasswordErrorMessage = '';
    _newPasswordKey = GlobalKey<FormState>();
    _currentPasswordKey = GlobalKey<FormState>();
    _newPasswordFocusNode = new FocusNode();
    _currentPasswordFocusNode = new FocusNode();
    _newPasswordFocusNode.addListener(() {
      if (!_newPasswordFocusNode.hasFocus) {
        _newPasswordKey.currentState?.validate();
      }
    });
    _currentPasswordFocusNode.addListener(() {
      if (!_currentPasswordFocusNode.hasFocus) {
        _currentPasswordKey.currentState?.validate();
      }
    });
    super.initState();
  }

  bool savable() {
    return newPassword.length > 5 && currentPassword.length > 5;
  }

  @override
  Widget build(BuildContext context) {
    return MyHookBottomFixedButton(
      provider: _savableProvider,
      onTapped: () async {
        _newPasswordFocusNode.unfocus();
        _currentPasswordFocusNode.unfocus();
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
              'パスワードを変更',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(fontWeight: FontWeight.w700, fontSize: 20),
            ),
            SizedBox(
              height: 40,
            ),
            Form(
              key: _currentPasswordKey,
              child: MyPasswordField(
                label: '現在のパスワード',
                focusNode: _currentPasswordFocusNode,
                onFieldSubmitted: (_) {
                  _currentPasswordFocusNode.unfocus();
                  _newPasswordFocusNode.requestFocus();
                },
                textInputAction: TextInputAction.next,
                validate: (text) {
                  if (currentPasswordErrorMessage.length > 0) {
                    String p = currentPasswordErrorMessage;
                    currentPasswordErrorMessage = '';
                    return p;
                  }
                  if (text == null || text.length < 6) {
                    return '6文字以上入力してください';
                  }
                  return null;
                },
                onChanged: (text) {
                  currentPassword = text;
                  ref.read(_savableProvider.notifier).setCurrentPassword(
                      text.length > 5 && currentPassword != newPassword);
                },
                onSaved: (text) {
                  this.currentPassword = text ?? '';
                },
              ),
            ),
            SizedBox(
              height: 16,
            ),
            Form(
              key: _newPasswordKey,
              child: MyPasswordField(
                label: '新しいパスワード',
                onFieldSubmitted: (_) {
                  _newPasswordFocusNode.unfocus();
                },
                textInputAction: TextInputAction.done,
                focusNode: _newPasswordFocusNode,
                validate: (text) {
                  if (currentPasswordErrorMessage.length > 0) {
                    String p = currentPasswordErrorMessage;
                    currentPasswordErrorMessage = '';
                    return p;
                  }
                  if (text == null || text.length < 6) {
                    return '6文字以上入力してください';
                  }
                  return null;
                },
                onChanged: (text) {
                  newPassword = text;
                  ref.read(_savableProvider.notifier).setNewPassword(
                      text.length > 5 && currentPassword != newPassword);
                },
                onSaved: (text) {
                  this.currentPassword = text ?? '';
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> save() async {
    if ((_newPasswordKey.currentState?.validate() ?? false) &&
        (_currentPasswordKey.currentState?.validate() ?? false)) {
      _currentPasswordKey.currentState!.save();
      _newPasswordKey.currentState!.save();
      try {
        User? firebaseUser = FirebaseAuth.instance.currentUser;
        String? email = firebaseUser?.email;
        if (firebaseUser == null || email == null) return;
        MyLoading.startLoading();
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email, password: this.currentPassword);
        await firebaseUser.reload();
        await firebaseUser.updatePassword(newPassword);
        await MyLoading.dismiss();
        ApplicationRoutes.pushReplacementNamed(
            '/settings/account/password/complete');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          newPasswordErrorMessage = 'パスワードが脆弱です';
          _newPasswordKey.currentState?.validate();
        } else if (e.code == 'wrong-password') {
          currentPasswordErrorMessage = 'パスワードが正しくありません。';
          _currentPasswordKey.currentState?.validate();
        } else {
          await MyLoading.dismiss();
          MyErrorDialog.show(e);
          return;
        }
        await MyLoading.dismiss();
      } catch (e) {
        await MyLoading.dismiss();
        MyErrorDialog.show(e);
      }
    }
  }
}

class PasswordChangeComplete extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(
          context: context,
          titleText: '',
          backButton: AppBarBackButton.none,
          actions: [MyBackButtonX()]),
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'パスワードを変更しました。',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
