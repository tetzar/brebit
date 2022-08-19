import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/user.dart';
import '../../../provider/auth.dart';
import '../home/navigation.dart';
import '../profile/others-profile.dart';
import '../widgets/user-card.dart';
import 'search.dart';

class AccountResult extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(inputFormProvider);
    List<AuthUser>? result = ref.read(inputFormProvider.notifier).users;
    List<Widget> userCards = <Widget>[];
    if (result != null) {
      if (result.length == 0 &&
          ref.read(inputFormProvider.notifier).word.length > 0) {
        userCards.add(Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '申し訳ありません！”${ref.read(inputFormProvider.notifier).word}”に関するユーザーはみつかりませんでした。',
            style: Theme.of(context)
                .textTheme
                .bodyText1
                ?.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
            textAlign: TextAlign.left,
          ),
        ));
      } else {
        result.forEach((user) {
          userCards.add(InkWell(
            onTap: () {
              onCardTap(ref, user);
            },
            child: UserCard(
              user: user,
              isFriend:
                  ref.read(authProvider.notifier).user?.isFriend(user) ?? false,
            ),
          ));
        });
      }
      if (result.length < 5) {
        List<AuthUser> recommendation =
            ref.read(inputFormProvider.notifier).recommendation?.users ?? [];
        int recommendationLength = recommendation.length;
        if (recommendationLength > 0) {
          userCards.add(Container(
            width: double.infinity,
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(top: 8),
            child: Text(
              'おすすめのアカウント',
              style: TextStyle(
                  color: Theme.of(context).disabledColor,
                  fontWeight: FontWeight.w400,
                  fontSize: 13),
            ),
          ));
        }
        for (int i = 0; i < min(recommendationLength, 5); i++) {
          AuthUser _user = recommendation[i];
          userCards.add(InkWell(
            onTap: () {
              onCardTap(ref, _user);
            },
            child: UserCard(
              user: recommendation[i],
              isFriend: ref.read(authProvider.notifier).user?.isFriend(_user) ??
                  false,
            ),
          ));
        }
      }
      // userCards.add(
      //   Container(
      //     margin: EdgeInsets.symmetric(vertical: 8),
      //     child: GestureDetector(
      //     onTap: () async {
      //       await reload(context);
      //     },
      //     child: Container(
      //       height: 34,
      //       width: 72,
      //       decoration: BoxDecoration(
      //           borderRadius: BorderRadius.circular(17),
      //           border:
      //               Border.all(color: Theme.of(context).colorScheme.secondary, width: 1)),
      //       alignment: Alignment.center,
      //       child: Text(
      //         '更新',
      //         style: TextStyle(
      //             color: Theme.of(context).colorScheme.secondary,
      //             fontWeight: FontWeight.w700,
      //             fontSize: 12),
      //       ),
      //     ),
      // ),
      //   ));
    }
    return Container(
      child: result == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Container(
              height: double.infinity,
              padding: EdgeInsets.only(top: 8, left: 24, right: 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: userCards,
                ),
              ),
            ),
    );
  }

  void onCardTap(WidgetRef ref, AuthUser user) {
    AuthUser? selfUser = ref.read(authProvider.notifier).user;
    if (selfUser != null && selfUser.id == user.id) {
      Home.pushNamed('/profile');
    } else {
      Home.push(
          MaterialPageRoute(builder: (context) => OtherProfile(user: user)));
    }
  }

  Future<void> reload(BuildContext context) async {}
}
