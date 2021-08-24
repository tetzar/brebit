
import '../../../../model/user.dart';
import '../../../../network/profile.dart';
import '../../../../provider/auth.dart';
import '../../../../route/route.dart';
import '../../general/loading.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/dialog.dart';
import '../../widgets/text-field.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _savableProvider = StateNotifierProvider.autoDispose(
    (ref) => SavableProvider(false)
);

class SavableProvider extends StateNotifier<bool> {
  SavableProvider(bool state) : super(state);
  void set(bool s) {
    state = s;
  }

  bool savable() {
    return state ?? false;
  }
}

class CustomIdForm extends StatefulWidget {
  @override
  _CustomIdFormState createState() => _CustomIdFormState();
}

class _CustomIdFormState extends State<CustomIdForm> {
  GlobalKey<FormState> _key;
  String customId;
  int stack;

  @override
  void initState() {
    _key = new GlobalKey<FormState>();
    customId = context.read(authProvider.state).user.customId;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: getMyAppBar(
            context: context,
          titleText: 'ユーザーネーム'
        ),
        body: MyHookBottomFixedButton(
          provider: _savableProvider,
          child: Container(
            padding: EdgeInsets.only(top: 32, left: 32, right: 32),
            alignment: Alignment.topCenter,
            child: Form(
                key: _key,
                child: MyUserNameField(
                  onValidate: (text) {
                  },
                  onSaved: (text) async {
                    this.customId = text;
                  },
                  onStateChange: (state) {
                    context.read(_savableProvider).set(
                        state == CustomIdFieldState.allowed
                    );
                    _key.currentState.validate();
                  },
                  initialValue: context.read(authProvider.state).user.customId,
                )),
          ),
          label: '保存',
          onTapped: () async {
            _key.currentState.save();
            await save(context);
          },
          enable: () {
            bool savable = context.read(_savableProvider).savable();
            return savable;
          },
        ));
  }

  Future<void> save(BuildContext ctx) async {
    try {
      MyLoading.startLoading();
      AuthUser user = await ProfileApi.saveProfile(
          {'name': null, 'custom_id': this.customId, 'bio': null});
      ctx.read(authProvider).setUser(user);
      await MyLoading.dismiss();
      ApplicationRoutes.pop();
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }
}
