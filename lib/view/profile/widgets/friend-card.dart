import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../model/user.dart';
import '../../../../provider/auth.dart';
import '../../home/navigation.dart';
import '../others-profile.dart';

class FriendCard extends ConsumerWidget {
  final AuthUser user;

  FriendCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        AuthUser? user = ref.read(authProvider.notifier).user;
        if (user == null) return;
        if (this.user.id != user.id) {
          Home.push(MaterialPageRoute(
              builder: (context) => OtherProfile(user: this.user)));
        } else {
          Home.pushNamed('/profile');
        }
      },
      child: Container(
        color: Theme.of(context).primaryColor,
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              child: CircleAvatar(
                child: ClipOval(
                  child: Stack(
                    children: <Widget>[
                      user.getImageWidget(),
                    ],
                  ),
                ),
                radius: 28,
                // backgroundImage: NetworkImage('https://via.placeholder.com/300'),
                backgroundColor: Colors.transparent,
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(left: 8),
                child: Column(
                  children: [
                    //---------------------------------
                    //  name and tag
                    //---------------------------------
                    Row(
                      children: [
                        Text(
                          user.name,
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1?.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                        ),
                        ref.read(authProvider.notifier).user?.isFriend(user) ??
                                false
                            ? Container(
                                padding: EdgeInsets.only(
                                  left: 8,
                                ),
                                height: 17,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(8)),
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                  child: Text(
                                    'フレンド',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                        color: Theme.of(context).primaryColor),
                                  ),
                                ),
                              )
                            : SizedBox(
                                height: 0,
                                width: 0,
                              )
                      ],
                    ),
                    //---------------------------------
                    //  custom id
                    //---------------------------------
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '@' + user.customId,
                        style: TextStyle(
                            color: Theme.of(context).textTheme.subtitle1?.color,
                            fontWeight: FontWeight.w400,
                            fontSize: 15),
                      ),
                    ),
                    //---------------------------------
                    //  bio
                    //---------------------------------
                    Container(
                      alignment: Alignment.centerLeft,
                      margin: EdgeInsets.only(top: 4),
                      child: Text(
                        user.bio,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText1?.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
