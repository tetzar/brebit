import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../api/partner.dart';
import '../../../model/partner.dart';
import '../../../model/user.dart';
import '../../../provider/auth.dart';
import '../../../provider/profile.dart';
import '../general/loading.dart';
import '../home/navigation.dart';
import '../profile/others-profile.dart';
import '../widgets/app-bar.dart';
import '../widgets/dialog.dart';

class FriendRequestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(context: context, titleText: 'フレンド申請'),
      body: RequestTiles(),
    );
  }
}

class RequestTiles extends HookWidget {
  @override
  Widget build(BuildContext context) {
    useProvider(authProvider.state);
    List<Partner> requestedList =
        context.read(authProvider.state).user.getRequestedPartners();
    return Container(
      height: double.infinity,
      width: MediaQuery.of(context).size.width,
      child: ListView.builder(
          itemCount: requestedList.length,
          itemBuilder: (context, int index) {
            return RequestTile(requestedList[index]);
          }),
    );
  }
}

class RequestTile extends StatefulWidget {
  final Partner partner;

  RequestTile(this.partner);

  @override
  _RequestTileState createState() => _RequestTileState();
}

class _RequestTileState extends State<RequestTile> {
  AuthUser _user;

  @override
  void initState() {
    this._user = widget.partner.user;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant RequestTile oldWidget) {
    this._user = widget.partner.user;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              if (context.read(authProvider.state).user.id == this._user.id) {
                Home.pushNamed('/profile');
              } else {
                Home.push(MaterialPageRoute(
                    builder: (context) => OtherProfile(user: this._user)));
              }
            },
            child: CircleAvatar(
              child: ClipOval(child: this._user.getImageWidget()),
              radius: 22,
              // backgroundImage: NetworkImage('https://via.placeholder.com/300'),
              backgroundColor: Colors.transparent,
            ),
          ),
          SizedBox(
            width: 8,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            this._user.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1
                                .copyWith(
                                    fontWeight: FontWeight.w700, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            height: 4,
                          ),
                          Text(
                            '@' + this._user.customId,
                            style: Theme.of(context)
                                .textTheme
                                .subtitle1
                                .copyWith(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        await acceptRequest(context);
                      },
                      child: Container(
                        margin: EdgeInsets.only(left: 4),
                        height: 34,
                        width: 72,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(17),
                            color: Theme.of(context).accentColor),
                        alignment: Alignment.center,
                        child: Text(
                          '承認',
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        await dennyRequest(context);
                      },
                      child: Container(
                        margin: EdgeInsets.only(left: 4),
                        height: 34,
                        width: 72,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(17),
                            color: Theme.of(context).primaryColor,
                            border: Border.all(
                                color: Theme.of(context).accentColor,
                                width: 1)),
                        alignment: Alignment.center,
                        child: Text(
                          '削除',
                          style: TextStyle(
                              color: Theme.of(context).accentColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 4,
                ),
                this._user.bio.length == 0
                    ? SizedBox(
                        height: 0,
                      )
                    : Text(
                        this._user.bio,
                        style: Theme.of(context).textTheme.bodyText1,
                      )
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> acceptRequest(BuildContext context) async {
    try {
      MyLoading.startLoading();
      Map<String, Partner> result = await PartnerApi.acceptPartnerRequest(
          context.read(authProvider.state).user.getPartner(this._user));
      context.read(authProvider).setPartner(result['self_relation']);
      if (context.read(profileProvider(this._user.id)).hasListeners) {
        context
            .read(profileProvider(this._user.id))
            .setPartner(result['other_relation']);
      }
      MyLoading.dismiss();
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }

  Future<void> dennyRequest(BuildContext context) async {
    try {
      MyLoading.startLoading();
      await PartnerApi.cancelPartnerRequest(widget.partner);
      context.read(authProvider).breakOffWithFriend(widget.partner);
      await MyLoading.dismiss();
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }
}
