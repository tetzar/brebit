import '../../../../model/partner.dart';
import '../../../../model/user.dart';
import '../../../../provider/auth.dart';
import '../../home/navigation.dart';
import '../../profile/others-profile.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/user-card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class Blocking extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(context: context, titleText: 'ブロック中'),
      body: BlockingList(),
    );
  }
}

class BlockingList extends HookWidget {

  void redirectToProfile(BuildContext ctx, AuthUser user) {
    if (ctx.read(authProvider.state).user.id == user.id) {
      Home.pushNamed('/profile');
    } else {
      Home.push(MaterialPageRoute(
          builder: (context) => OtherProfile(user: user)));
    }
  }
  @override
  Widget build(BuildContext context) {
    useProvider(authProvider.state);
    List<Partner> partners =
        context.read(authProvider.state).user.getBlockingList();
    return Container(
      child: ListView.builder(
        itemCount: partners.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              redirectToProfile(context, partners[index].user);
            },
              child: UserCard(user: partners[index].user, isFriend: false));
        },
      ),
    );
  }
}
