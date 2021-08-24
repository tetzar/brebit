import '../../../../model/category.dart';
import '../../../../model/partner.dart';
import '../../../../model/user.dart';
import '../../../../provider/auth.dart';
import '../../../../provider/profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final Map<CategoryName, String> _categoryName = {
  CategoryName.cigarette: 'たばこ',
  CategoryName.alcohol: 'お酒',
  CategoryName.sweets: 'お菓子',
  CategoryName.sns: 'SNS',
  CategoryName.notCategorized: '？？',
};

final Map<CategoryName, String> _imagePath = {
  CategoryName.cigarette: 'assets/icon/cigarette.svg',
  CategoryName.alcohol: 'assets/icon/liquor.svg',
  CategoryName.sweets: 'assets/icon/sweet.svg',
  CategoryName.sns: 'assets/icon/sns.svg',
  CategoryName.notCategorized: 'assets/icon/close.svg',
};

class ProfileCard extends StatefulWidget {
  final AuthUser user;

  ProfileCard({@required this.user});

  @override
  _ProfileCardState createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  String name;

  @override
  void initState() {
    name = context.read(profileProvider(widget.user.id).state).user.name;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AuthUser user = context.read(profileProvider(widget.user.id).state).user;
    return Container(
      color: Theme.of(context).primaryColor,
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(left: 24, right: 24, top: 24),
      child: Container(
        width: double.infinity,
        child: Column(
          children: [
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    child: CircleAvatar(
                      child: ClipOval(
                        child: Stack(
                          children: <Widget>[
                            user.getImageWidget(),
                          ],
                        ),
                      ),
                      radius: 40,
                      // backgroundImage: NetworkImage('https://via.placeholder.com/300'),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  Expanded(
                      child: Container(
                          padding: EdgeInsets.only(
                            left: 24,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 21,
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  user.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyText1
                                      .copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 17),
                                ),
                              ),
                              PartnerStateTag(user: user)
                            ],
                          ))),
                ],
              ),
            ),
            HookBuilder(
              builder: (BuildContext context) {
                useProvider(authProvider.state);
                if (context.read(authProvider.state).user.isBlocking(user)) {
                  return SizedBox(
                    height: 0,
                  );
                }
                return user.habitCategories.length > 0
                    ? Container(
                        padding: EdgeInsets.only(
                          top: 16,
                          bottom: 16,
                        ),
                        width: double.infinity,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (Category category in user.habitCategories)
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      _imagePath[category.name],
                                      width: 14,
                                      height: 14,
                                      color: Theme.of(context).accentColor,
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(left: 8),
                                      child: Text(
                                          _categoryName[category.name] + 'をやめる',
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1),
                                    )
                                  ],
                                ),
                            ]),
                      )
                    : SizedBox(
                        height: 0,
                      );
              },
            ),
            HookBuilder(
              builder: (context) {
                useProvider(authProvider.state);
                if (context.read(authProvider.state).user.isBlocking(user)) {
                  return SizedBox(height: 0);
                }
                return user.bio.length > 0
                    ? Container(
                        padding: EdgeInsets.only(bottom: 8),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          user.bio,
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.subtitle1.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                        ) // child: null,
                        )
                    : SizedBox(height: 0);
              },
            )
          ],
        ),
      ),
    );
  }
}

class PartnerStateTag extends HookWidget {
  final AuthUser user;

  PartnerStateTag({@required this.user});

  @override
  Widget build(BuildContext context) {
    useProvider(authProvider.state);
    Widget partnerStateTag = SizedBox(
      height: 21,
    );
    Partner _partner = context.read(authProvider.state).user.getPartner(user);
    if (_partner != null) {
      PartnerState _partnerState = _partner.getState();
      if (_partnerState == PartnerState.partner) {
        partnerStateTag = Container(
          height: 21,
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).accentColor,
          ),
          alignment: Alignment.center,
          child: Text(
            'フレンド',
            style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w400,
                fontSize: 11),
          ),
        );
      } else if (_partnerState == PartnerState.request) {
        partnerStateTag = Container(
          height: 21,
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).primaryColor,
              border:
                  Border.all(color: Theme.of(context).accentColor, width: 0.5)),
          alignment: Alignment.center,
          child: Text(
            'フレンド申請中',
            style: TextStyle(
                color: Theme.of(context).accentColor,
                fontWeight: FontWeight.w400,
                fontSize: 11),
          ),
        );
      } else if (_partnerState == PartnerState.block) {
        partnerStateTag = Container(
          height: 21,
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).accentTextTheme.subtitle1.color,
          ),
          alignment: Alignment.center,
          child: Text(
            'ブロック中',
            style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w400,
                fontSize: 11),
          ),
        );
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [partnerStateTag],
    );
  }
}
