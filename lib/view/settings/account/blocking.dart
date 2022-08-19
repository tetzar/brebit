import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../model/partner.dart';
import '../../../../model/user.dart';
import '../../../../provider/auth.dart';
import '../../home/navigation.dart';
import '../../profile/others-profile.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/user-card.dart';

class Blocking extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(context: context, titleText: 'ブロック中'),
      body: BlockingList(),
    );
  }
}

class BlockingList extends ConsumerWidget {
  void redirectToProfile(WidgetRef ref, AuthUser user) {
    AuthUser? selfUser = ref.read(authProvider.notifier).user;
    if (selfUser != null && selfUser.id == user.id) {
      Home.pushNamed('/profile');
    } else {
      Home.push(
          MaterialPageRoute(builder: (context) => OtherProfile(user: user)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authProvider);
    List<Partner> partners =
        ref.read(authProvider.notifier).user?.getBlockingList() ?? [];
    return Container(
      child: ListView.builder(
        itemCount: partners.length,
        itemBuilder: (context, index) {
          return InkWell(
              onTap: () {
                redirectToProfile(ref, partners[index].user);
              },
              child: UserCard(user: partners[index].user, isFriend: false));
        },
      ),
    );
  }
}
