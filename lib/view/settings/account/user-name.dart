
import 'package:brebit/view/general/error-widget.dart';

import '../../../../model/user.dart';
import '../../../../api/profile.dart';
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
    return state;
  }
}

class CustomIdForm extends ConsumerStatefulWidget {
  @override
  _CustomIdFormState createState() => _CustomIdFormState();
}

class _CustomIdFormState extends ConsumerState<CustomIdForm> {
  late GlobalKey<FormState> _key;
  String customId = '';
  int? stack;

  @override
  void initState() {
    _key = new GlobalKey<FormState>();
    customId = ref.read(authProvider.notifier).user?.customId ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AuthUser? user = ref.read(authProvider.notifier).user;
    if (user == null) return ErrorToHomeWidget();
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
                    this.customId = text ?? '';
                  },
                  onStateChange: (state) {
                    ref.read(_savableProvider.notifier).set(
                        state == CustomIdFieldState.allowed
                    );
                    _key.currentState?.validate();
                  },
                  initialValue: user.customId,
                )),
          ),
          label: '保存',
          onTapped: () async {
            _key.currentState?.save();
            await save(context);
          },
          enable: () {
            bool savable = ref.read(_savableProvider.notifier).savable();
            return savable;
          },
        ));
  }

  Future<void> save(BuildContext ctx) async {
    try {
      MyLoading.startLoading();
      AuthUser user = await ProfileApi.saveProfile(
          {'name': null, 'custom_id': this.customId, 'bio': null});
      ref.read(authProvider.notifier).updateState(user: user);
      await MyLoading.dismiss();
      ApplicationRoutes.pop();
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }
}
