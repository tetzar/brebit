import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingProperty {
  SettingProperty(this.name, this.func);

  String name;
  Future<void> Function(WidgetRef, BuildContext) func;
  bool arrow = true;
  Color? textColor;
}

class SettingListTileBox extends ConsumerWidget {
  final List<SettingProperty> properties;

  SettingListTileBox({required this.properties});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Widget> propertyTiles = <Widget>[];
    properties.forEach((property) {
      propertyTiles.add(new InkWell(
        onTap: () async {
          await property.func(ref, context);
        },
        child: Container(
          height: 52,
          padding: EdgeInsets.only(
            left: 16,
            top: 10,
            bottom: 10,
            right: 10,
          ),
          width: double.infinity,
          alignment: Alignment.centerLeft,
          child: Row(
            children: property.arrow
                ? [
                    Expanded(
                      child: Text(
                        property.name,
                        style: property.textColor == null
                            ? TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyText1
                                    ?.color)
                            : TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: property.textColor),
                      ),
                    ),
                    Padding(
                      child: SvgPicture.asset('assets/icon/setting_arrow.svg',
                          height: 32, width: 32),
                      padding: const EdgeInsets.symmetric(horizontal: 11.87),
                    )
                  ]
                : [
                    Expanded(
                      child: Text(
                        property.name,
                        style: property.textColor == null
                            ? TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyText1
                                    ?.color)
                            : TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: property.textColor),
                      ),
                    ),
                  ],
          ),
        ),
      ));
    });
    return Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        child: Column(
          children: propertyTiles,
        ));
  }
}

class AuthSettingProperty {
  AuthSettingProperty(this.authorized, this.name, this.func);

  bool authorized;
  Future<void> Function(WidgetRef, BuildContext) func;
  String name;
  Color? textColor;
}

class AuthSettingListTileBox extends ConsumerWidget {
  final List<AuthSettingProperty> properties;

  AuthSettingListTileBox({required this.properties});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Widget> propertyTiles = <Widget>[];
    properties.forEach((property) {
      propertyTiles.add(new InkWell(
        onTap: () async {
          await property.func(ref, context);
        },
        child: Container(
          height: 52,
          padding: EdgeInsets.only(
            left: 16,
            top: 10,
            bottom: 10,
            right: 10,
          ),
          width: double.infinity,
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  property.name,
                  style: property.textColor == null
                      ? TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: Theme.of(context).textTheme.bodyText1?.color)
                      : TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: property.textColor),
                ),
              ),
              Container(
                  width: 96,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(17)),
                    color: Theme.of(context).primaryColor,
                  ),
                  alignment: Alignment.center,
                  child: property.authorized
                      ? Text(
                          '連携済み',
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.subtitle1?.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        )
                      : Text(
                          '連携する',
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.subtitle1?.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ))
            ],
          ),
        ),
      ));
    });
    return Container(
        margin: EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        child: Column(
          children: propertyTiles,
        ));
  }
}

class PrivacySettingProperty {
  PrivacySettingProperty(this.hidden, this.name, this.func);

  bool hidden;
  Function func;
  String name;
  Color? textColor;
}

class PrivacySettingListTileBox extends StatelessWidget {
  final List<PrivacySettingProperty> properties;

  PrivacySettingListTileBox({required this.properties});

  @override
  Widget build(BuildContext context) {
    List<Widget> propertyTiles = <Widget>[];
    properties.forEach((property) {
      propertyTiles.add(new InkWell(
        onTap: () async {
          await property.func(context);
        },
        child: Container(
          height: 52,
          padding: EdgeInsets.only(
            left: 16,
            top: 10,
            bottom: 10,
            right: 10,
          ),
          width: double.infinity,
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  property.name,
                  style: property.textColor == null
                      ? TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: Theme.of(context).textTheme.bodyText1?.color)
                      : TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: property.textColor),
                ),
              ),
              // ToDo replace icon to svg picture
              Container(
                  width: 96,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(17)),
                    color: Theme.of(context).primaryColor,
                  ),
                  alignment: Alignment.center,
                  child: property.hidden
                      ? Text(
                          '非公開',
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.subtitle1?.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        )
                      : Text(
                          '公開',
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.subtitle1?.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ))
            ],
          ),
        ),
      ));
    });
    return Container(
        margin: EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        child: Column(
          children: propertyTiles,
        ));
  }
}

class NotificationSettingProperty {
  NotificationSettingProperty(this.enable, this.name, this.onSwitch);

  bool enable;
  NotificationToggleOnSwitch onSwitch;
  String name;
  Color? textColor;
}

class NotificationSettingListTileBox extends StatelessWidget {
  final List<NotificationSettingProperty> properties;

  NotificationSettingListTileBox({required this.properties});

  @override
  Widget build(BuildContext context) {
    List<Widget> propertyTiles = <Widget>[];
    properties.forEach((property) {
      propertyTiles.add(new Container(
        height: 52,
        padding: EdgeInsets.only(
          left: 16,
          top: 10,
          bottom: 10,
          right: 10,
        ),
        width: double.infinity,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: Text(
                property.name,
                style: property.textColor == null
                    ? TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: Theme.of(context).textTheme.bodyText1?.color)
                    : TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: property.textColor),
              ),
            ),
            NotificationToggleSwitch(property.enable, property.onSwitch)
          ],
        ),
      ));
    });
    return Container(
        margin: EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        child: Column(
          children: propertyTiles,
        ));
  }
}

typedef Future<void> NotificationToggleOnSwitch(bool);

class NotificationToggleSwitch extends StatefulWidget {
  final bool initialValue;
  final NotificationToggleOnSwitch onSwitch;

  @override
  _NotificationToggleSwitchState createState() =>
      _NotificationToggleSwitchState();

  NotificationToggleSwitch(this.initialValue, this.onSwitch);
}

class _NotificationToggleSwitchState extends State<NotificationToggleSwitch> {
  late ValueNotifier<bool> _controller;

  @override
  void initState() {
    _controller = new ValueNotifier(widget.initialValue);
    _controller.addListener(() async {
      await widget.onSwitch(_controller.value);
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant NotificationToggleSwitch oldWidget) {
    _controller.value = widget.initialValue;
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdvancedSwitch(
      controller: _controller,
      activeColor: Theme.of(context).colorScheme.secondary,
      inactiveColor: Theme.of(context).primaryColorDark,
      width: 51,
      height: 30,
      borderRadius: BorderRadius.circular(15),
      thumb: Container(
        height: 26,
        width: 26,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).primaryColor,
            boxShadow: [
              BoxShadow(
                  color: Theme.of(context).shadowColor,
                  offset: Offset(0, 3),
                  blurRadius: 8)
            ]),
      ),
    );
  }
}
