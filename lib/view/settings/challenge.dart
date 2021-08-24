import '../../../model/category.dart';
import '../../../model/habit.dart';
import '../../../model/user.dart';
import '../../../provider/auth.dart';
import '../../../provider/home.dart';
import '../../../route/route.dart';
import '../general/loading.dart';
import '../widgets/app-bar.dart';
import '../widgets/bottom-sheet.dart';
import '../widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChallengeSettings extends HookWidget {
  final Map<CategoryName, String> categoryTitle = {
    CategoryName.cigarette: 'たばこを減らす',
    CategoryName.alcohol: 'お酒を控える',
    CategoryName.sweets: 'お菓子を控える ',
    CategoryName.sns: 'SNSを控える',
  };

  final Map<CategoryName, String> categoryImageUrl = {
    CategoryName.cigarette: 'assets/icon/cigarette.svg',
    CategoryName.alcohol: 'assets/icon/liquor.svg',
    CategoryName.sweets: 'assets/icon/sweet.svg',
    CategoryName.sns: 'assets/icon/sns.svg',
  };


  @override
  Widget build(BuildContext context) {
    useProvider(authProvider.state);
    AuthUser user = context
        .read(authProvider.state)
        .user;
    List<Widget> columnChildren = <Widget>[];
    List<CategoryName> activeCategories = user.getActiveHabitCategories().map(
            (category) => category.name
    ).toList();
    List<CategoryName> suspendingCategories = user
        .getSuspendingHabitCategories().map(
            (category) => category.name
    ).toList();
    List<CategoryName> unStartedCategories = CategoryName.values.where(
            (categoryName) =>
        categoryName != CategoryName.notCategorized
            && !activeCategories.contains(categoryName) &&
            !suspendingCategories.contains(categoryName)).toList();
    if (activeCategories.isNotEmpty) {
      columnChildren.add(Text(
        '挑戦中のチャレンジ',
        style: Theme
            .of(context)
            .textTheme
            .subtitle1,
      ));
      for (CategoryName _categoryName in activeCategories) {
        columnChildren.add(CategoryTile(categoryImageUrl[_categoryName],
            categoryTitle[_categoryName], _categoryName));
      }
    }
    if (suspendingCategories.isNotEmpty) {
      columnChildren.add(Container(
        margin: EdgeInsets.only(top: 8),
        child: Text(
          '一時停止中のチャレンジ',
          style: Theme
              .of(context)
              .textTheme
              .subtitle1,
        ),
      ));
      for (CategoryName _categoryName in suspendingCategories) {
        columnChildren.add(CategoryTile(categoryImageUrl[_categoryName],
            categoryTitle[_categoryName], _categoryName));
      }
    }
    if (unStartedCategories.isNotEmpty) {
      columnChildren.add(Container(
        margin: EdgeInsets.only(top: 8),
        child: Text(
          '開始可能なチャレンジ',
          style: Theme
              .of(context)
              .textTheme
              .subtitle1,
        ),
      ));
      for (CategoryName _categoryName in unStartedCategories) {
        columnChildren.add(CategoryTile(categoryImageUrl[_categoryName],
            categoryTitle[_categoryName], _categoryName));
      }
    }
    return Scaffold(
      appBar: getMyAppBar(context: context, titleText: 'チャレンジ'),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columnChildren,
          ),
        ),
      ),
    );

  }

  // Future<void> stop(BuildContext context) async {
  //   Habit _habit = context.read(authProvider).stopHabit(
  //       categoryName
  //   );
  //   context.read(homeProvider).setHabit(_habit);
  // }
}

class CategoryTile extends StatelessWidget {
  final String imageUrl;
  final String title;
  final CategoryName categoryName;

  CategoryTile(this.imageUrl, this.title, this.categoryName);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          await startOrStop(context, categoryName);
        },
        child: Container(
          decoration: BoxDecoration(
              color: Theme
                  .of(context)
                  .primaryColor,
              borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.all(16),
          alignment: Alignment.center,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                imageUrl,
                width: 24,
                height: 24,
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: 16),
                  child: Text(title,
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> startOrStop(BuildContext ctx, CategoryName categoryName) async {
    if (ctx
        .read(authProvider.state)
        .user
        .isActiveHabitCategory(categoryName)) {
      showCustomBottomSheet(
          items: [
            NormalBottomSheetItem(
                context: ctx,
                text: '“$title”チャレンジをやめる',
                onSelect: () async {
                  await suspend(ctx, categoryName);
                  ApplicationRoutes.pop();
                }),
            CancelBottomSheetItem(
                context: ctx,
                onSelect: () {
                  ApplicationRoutes.pop();
                })
          ],
          hintText: 'チャレンジをやめても記録は保持され、\n再開することが可能です。\nスモールステップは\n直前のスモールステップからになります。',
          backGroundColor: Theme
              .of(ctx)
              .primaryColor,
          context: ApplicationRoutes.materialKey.currentContext);
    } else {
      showCustomBottomSheet(
          items: [
            NormalBottomSheetItem(
                context: ctx,
                text: '“$title”チャレンジを開始する',
                onSelect: () async {
                  ApplicationRoutes.pop();
                  await start(ctx, categoryName);
                }),
            CancelBottomSheetItem(
                context: ctx,
                onSelect: () {
                  ApplicationRoutes.pop();
                })
          ],
          hintText: '現在のチャレンジから”お酒を控える”に変更します。\n現在のチャレンジの記録は保持され、\n再開することができます。',
          backGroundColor: Theme
              .of(ctx)
              .primaryColor,
          context: ApplicationRoutes.materialKey.currentContext);
    }
  }

  Future<void> start(BuildContext context, CategoryName categoryName) async {
    final Map<CategoryName, String> routeName = {
      CategoryName.cigarette: 'cigarette',
      CategoryName.alcohol: 'alcohol',
      CategoryName.sweets: 'sweets',
      CategoryName.sns: 'sns',
    };
    if (context
        .read(authProvider.state)
        .user
        .isSuspendingCategory(categoryName)) {
      try {
        MyLoading.startLoading();
        Habit _habit = await context.read(authProvider).restartHabit(categoryName);
        await context.read(homeProvider).restart(_habit);
        await MyLoading.dismiss();
      } catch (e) {
        await MyLoading.dismiss();
        MyErrorDialog.show(e);
      }
    } else {
      ApplicationRoutes.pushNamed('/category/${routeName[categoryName]}');
    }
  }

  Future<void> suspend(BuildContext context, CategoryName categoryName) async {
    try {
      MyLoading.startLoading();
      Habit habit = await context.read(authProvider).suspendHabit(
          categoryName
      );
      await context.read(homeProvider).suspend(habit);
      await MyLoading.dismiss();
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }
}
