import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../model/category.dart';
import '../../../../model/user.dart';
import '../../../../provider/auth.dart';
import '../../../../route/route.dart';

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

class ProfileCard extends ConsumerStatefulWidget {
  final GlobalKey containerKey;

  ProfileCard({required this.containerKey});

  @override
  _ProfileCardState createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<ProfileCard> {
  String name = '';
  String currentName = '';
  late TextEditingController _textEditingController;

  @override
  void initState() {
    name = ref.read(authProvider.notifier).user?.name ?? name;
    currentName = name;
    _textEditingController = new TextEditingController();
    _textEditingController.text = currentName;
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    AuthUser? user = ref.read(authProvider.notifier).user;
    if (user != null) {
      if (currentName != user.name) {
        currentName = user.name;
        _textEditingController.text = currentName;
      }
    }
    return Container(
      key: widget.containerKey,
      color: Theme.of(context).primaryColor,
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Container(
        width: double.infinity,
        child: Column(
          children: [
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RawMaterialButton(
                      onPressed: () {
                        ApplicationRoutes.pushNamed('/profile/image');
                      },
                      child: Center(
                        child: CircleAvatar(
                          child: ClipOval(
                              child: user?.getImageWidget() ??
                                  AuthUser.getDefaultImage()),
                          radius: 40,
                          // backgroundImage: NetworkImage('https://via.placeholder.com/300'),
                          backgroundColor: Colors.transparent,
                        ),
                      )),
                  Expanded(
                      child: Container(
                    padding: EdgeInsets.only(
                      left: 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          child: Focus(
                            onFocusChange: (bool focus) async {
                              if (!focus) {
                                if (currentName != name && name.length > 0) {
                                  ref
                                      .read(authProvider.notifier)
                                      .saveName(name);
                                }
                              }
                            },
                            child: TextFormField(
                              controller: _textEditingController,
                              onChanged: (String value) {
                                name = value;
                              },
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                              textAlign: TextAlign.left,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(0),
                                fillColor: Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            (user != null && user.habitCategories.length > 0)
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
                                  _imagePath[category.name]!,
                                  width: 14,
                                  height: 14,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                Container(
                                  margin: EdgeInsets.only(left: 8),
                                  child: Text(
                                      _categoryName[category.name]! + 'をやめる',
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
                  ),
            (user != null && user.bio.length > 0)
                ? Container(
                    padding: EdgeInsets.only(bottom: 8),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      user.bio,
                      style: TextStyle(
                          color: Theme.of(context).textTheme.subtitle1?.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w400),
                    ) // child: null,
                    )
                : SizedBox(height: 0)
          ],
        ),
      ),
    );
  }
}
