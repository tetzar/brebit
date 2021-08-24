import '../../../provider/auth.dart';
import '../general/loading.dart';
import '../widgets/app-bar.dart';
import '../widgets/dialog.dart';
import '../widgets/text-field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../main.dart';

class NameInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: getMyAppBar(context: context, titleText: '新規登録'),
        backgroundColor: Theme.of(context).primaryColor,
        body: NameInputForm());
  }
}

class NameFormSavableProviderState {
  bool nickName;
  bool userName;
}

class NameFormSavableProvider
    extends StateNotifier<NameFormSavableProviderState> {
  NameFormSavableProvider(NameFormSavableProviderState state) : super(state);

  set nickName(bool s) {
    if (this.state.nickName != s) {
      state = state..nickName = s;
    }
  }

  set userName(bool s) {
    if (this.state.userName != s) {
      state = state..userName = s;
    }
  }

  bool savable() {
    return (state.nickName ?? false) && (state.userName ?? false);
  }
}

final _nameFormSavableProvider = StateNotifierProvider.autoDispose(
    (ref) => NameFormSavableProvider(NameFormSavableProviderState()));

class NameInputForm extends StatefulWidget {
  @override
  _NameInputFormState createState() => _NameInputFormState();
}

class _NameInputFormState extends State<NameInputForm> {
  String nickName;
  String userName;

  FocusNode _nickNameFocusNode;
  FocusNode _userNameFocusNode;

  List<GlobalKey<FormState>> _keys;

  @override
  void initState() {
    _keys = [
      GlobalKey<FormState>(),
      GlobalKey<FormState>(),
    ];
    _userNameFocusNode = new FocusNode();
    _nickNameFocusNode = new FocusNode();
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
    super.initState();
  }

  @override
  void dispose() {
    _userNameFocusNode.dispose();
    _nickNameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MyHookBottomFixedButton(
      provider: _nameFormSavableProvider,
      enable: () {
        return context.read(_nameFormSavableProvider).savable();
      },
      onTapped: () async {
        await submitWithFirebase(context);
      },
      label: '新規登録',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _keys[0],
              child: MyTextField(
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  _nickNameFocusNode.unfocus();
                  _userNameFocusNode.requestFocus();
                },
                focusNode: _nickNameFocusNode,
                validate: (text) {
                  return text.length == 0 ? '入力してください' : null;
                },
                onChanged: (text) {
                  context.read(_nameFormSavableProvider).nickName =
                      text.length > 0;
                },
                label: 'ニックネーム',
                hintText: 'やまだ　たろう',
                onSaved: (text) {
                  nickName = text;
                },
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Form(
                key: _keys[1],
                child: MyUserNameField(
                  onValidate: (_) {},
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    _userNameFocusNode.unfocus();
                  },
                  focusNode: _userNameFocusNode,
                  onStateChange: (customIdState) {
                    context.read(_nameFormSavableProvider).userName =
                        customIdState == CustomIdFieldState.allowed;
                    _keys[1].currentState.validate();
                  },
                  onSaved: (text) async {
                    this.userName = text;
                  },
                ))
          ],
        ),
      ),
    );
  }

  Future<void> submitWithFirebase(BuildContext context) async {
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
    }
    if (valid) {
      MyLoading.startLoading();
      try {
        User firebaseUser = FirebaseAuth.instance.currentUser;
        await context
            .read(authProvider)
            .registerWithFirebase(nickName, userName, firebaseUser);
        await MyApp.initialize(context);
        await MyLoading.dismiss();
        Navigator.of(context).pushReplacementNamed("/home");
      } catch (e) {
        await MyLoading.startLoading();
        MyErrorDialog.show(e);
      }
    }
  }
}
