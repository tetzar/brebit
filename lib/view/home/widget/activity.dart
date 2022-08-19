import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../model/category.dart';
import '../../../../model/habit.dart';
import '../../../../model/habit_log.dart';
import '../../../../provider/home.dart';
import '../../../../route/route.dart';
import '../../profile/did-confirmation.dart';
import '../../timeline/create_post.dart';

final _activityProvider =
    StateNotifierProvider.autoDispose((ref) => ActivityProvider(<HabitLog>[]));

class ActivityProvider extends StateNotifier<List<HabitLog>> {
  ActivityProvider(List<HabitLog> state) : super(state);

  DateTime t = DateTime.now();
  Function? onOtherTap;

  void set(List<HabitLog> logs, DateTime time, {Function? onOtherTap}) {
    Function? thisOnOtherTap = this.onOtherTap;
    if (thisOnOtherTap != null && time != this.t) {
      thisOnOtherTap();
    }
    t = time;
    this.onOtherTap = onOtherTap;
    state = logs;
  }

  void setOnOtherTap(Function onOtherTap) {
    this.onOtherTap = onOtherTap;
  }

  void setTime(DateTime time) {
    this.t = time;
  }

  List<HabitLog> getList() {
    return [...state];
  }
}

class HomeActivity extends ConsumerStatefulWidget {
  @override
  _HomeActivityState createState() => _HomeActivityState();
}

class _HomeActivityState extends ConsumerState<HomeActivity> {
  late StreamController<double> _streamController;
  late PageController _pageController;
  late GlobalKey _bodyKey;
  Map<int, GlobalKey> _keyHolder = {};
  List<int> hasLoadedMonths = [];
  late Habit habit;

  void dailyCardAnimate() {
    BuildContext? currentContext = _bodyKey.currentContext;
    if (currentContext == null) return;
    RenderBox _box = currentContext.findRenderObject() as RenderBox;
    double _bodyHeight = _box.size.height;
    double pagePosition = _pageController.page ?? 0;

    BuildContext? _smallerBoxContext =
        _keyHolder[pagePosition.floor()]?.currentContext;
    BuildContext? _largerBoxContext =
        _keyHolder[pagePosition.ceil()]?.currentContext;
    if (_smallerBoxContext == null || _largerBoxContext == null) return;
    double rate = pagePosition - (pagePosition.floor()).toDouble();
    RenderBox _smallerBox = _smallerBoxContext.findRenderObject() as RenderBox;
    RenderBox _largerBox = _largerBoxContext.findRenderObject() as RenderBox;
    double _position =
        (_smallerBox.localToGlobal(_box.globalToLocal(Offset.zero)).dy +
                    _smallerBox.size.height) *
                (1 - rate) +
            (_largerBox.localToGlobal(_box.globalToLocal(Offset.zero)).dy +
                    _largerBox.size.height) *
                rate;
    _streamController.sink.add(_bodyHeight - _position);
  }

  @override
  void initState() {
    _keyHolder = <int, GlobalKey>{};
    _bodyKey = GlobalKey();
    Habit? habit = ref.read(homeProvider.notifier).getHabit();
    if (habit == null) {
      ApplicationRoutes.popUntil('/home');
      return;
    }
    this.habit = habit;
    HabitLog? startLog = habit.getLatestLogIn([HabitLogStateName.started]);
    if (startLog == null) {
      ApplicationRoutes.popUntil('/home');
      return;
    }
    int months = (DateTime.now().year - startLog.createdAt.year) * 12 +
        DateTime.now().month -
        startLog.createdAt.month +
        1;
    _pageController =
        new PageController(viewportFraction: 0.85, initialPage: months - 1);
    _pageController.addListener(() {
      dailyCardAnimate();
    });
    _streamController = new StreamController<double>();
    List<HabitLog> _logs = habit.habitLogs;
    List<List<HabitLog>> _collected = HabitLog.collectByDate(_logs);
    DateTime _now = DateTime.now();
    List<HabitLog>? _logInADay = _collected.firstWhere((collection) {
      return collection.first.createdAt.year == _now.year &&
          collection.first.createdAt.month == _now.month &&
          collection.first.createdAt.day == _now.day;
    }, orElse: () => []);
    ref.read(_activityProvider.notifier).set(_logInADay, _now);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        dailyCardAnimate();
      }
    });
    hasLoadedMonths = <int>[];
    super.initState();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  int dateTimeToMonthId(DateTime t) {
    return t.year * 100 + t.month;
  }

  DateTime monthIdToDateTime(int id) {
    int year = id ~/ 100;
    int month = id % 100;
    return DateTime.parse(
        '$year-${month ~/ 10 == 0 ? '0' + month.toString() : month.toString()}-01');
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(homeProvider);
    List<HabitLog> _logs = habit.habitLogs;
    List<List<HabitLog>> _collected = HabitLog.collectByDate(_logs);
    SplayTreeMap<int, List<List<HabitLog>>> _monthlyCollected =
        SplayTreeMap<int, List<List<HabitLog>>>();
    DateTime? _t;
    List<List<HabitLog>>? _monthlyCollection;
    int month = DateTime.now().month;
    int year = DateTime.now().year;
    while (month > _collected.first.first.createdAt.month ||
        year > _collected.first.first.createdAt.year) {
      String timeText = '';
      timeText += year.toString() + '-';
      timeText += month ~/ 10 == 0 ? '0$month-01' : '$month-01';
      _monthlyCollected[dateTimeToMonthId(DateTime.parse(timeText))] = [];
      month--;
      if (month < 1) {
        month = 12;
        year--;
      }
    }
    for (List<HabitLog> dailyLogs in _collected) {
      if (_t == null) {
        _monthlyCollection = <List<HabitLog>>[dailyLogs];
        _t = dailyLogs.first.createdAt;
      } else {
        if (_t.month != dailyLogs.first.createdAt.month &&
            _monthlyCollection != null) {
          String timeText = '';
          timeText += _t.year.toString() + '-';
          timeText +=
              _t.month ~/ 10 == 0 ? '0${_t.month}-01' : '${_t.month}-01';
          _monthlyCollected[dateTimeToMonthId(DateTime.parse(timeText))] =
              _monthlyCollection;
          _t = dailyLogs.first.createdAt;
          _monthlyCollection = <List<HabitLog>>[dailyLogs];
        } else {
          if (_monthlyCollection == null) {
            _monthlyCollection = <List<HabitLog>>[dailyLogs];
          } else {
            _monthlyCollection.add(dailyLogs);
          }
        }
      }
      if (_collected.last == dailyLogs) {
        String timeText = '';
        timeText += _t.year.toString() + '-';
        timeText += _t.month ~/ 10 == 0 ? '0${_t.month}-01' : '${_t.month}-01';
        _monthlyCollected[dateTimeToMonthId(DateTime.parse(timeText))] =
            _monthlyCollection;
      }
    }
    // _monthlyCollected[201502] = [];
    return Container(
      key: _bodyKey,
      width: MediaQuery.of(context).size.width,
      height: double.infinity,
      color: Theme.of(context).primaryColor,
      padding: EdgeInsets.only(top: 16),
      child: Stack(
        children: [
          Container(
              height: double.infinity,
              child: PageView.builder(
                itemCount: _monthlyCollected.length,
                controller: _pageController,
                itemBuilder: (_, i) {
                  GlobalKey _key = new GlobalKey();
                  _keyHolder[i] = _key;
                  return MonthlyCard(
                      _key,
                      _monthlyCollected.values.toList()[i],
                      monthIdToDateTime(_monthlyCollected.keys.toList()[i]),
                      this.habit);
                },
              )),
          Positioned(
            bottom: 0,
            child: HookBuilder(
              builder: (context) {
                ref.watch(_activityProvider);
                return StreamBuilder<double>(
                    stream: _streamController.stream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        double _height = max(102, snapshot.data!);
                        return Container(
                          height: _height,
                          width: MediaQuery.of(context).size.width,
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.075 + 4,
                          ),
                          child: LogCard(
                              ref.read(_activityProvider.notifier).getList(),
                              ref.read(_activityProvider.notifier).t,
                              _height),
                        );
                      }
                      return SizedBox(
                        height: 0,
                      );
                    });
              },
            ),
          )
        ],
      ),
    );
  }
}

class MonthlyCard extends StatelessWidget {
  final List<List<HabitLog>?> monthlyLogs;
  final DateTime date;
  final Habit habit;
  final GlobalKey containerKey;

  MonthlyCard(this.containerKey, this.monthlyLogs, this.date, this.habit);

  @override
  Widget build(BuildContext context) {
    if (monthlyLogs.length > 0 && monthlyLogs.first == null) {
      DateTime firstDayOfMonth = DateTime.parse(
          '${date.year}-${date.month ~/ 10 == 0 ? '0' + date.month.toString() : date.month}-01');
      int weekDay = firstDayOfMonth.weekday % 7;
      int monthlyDays = 28;
      DateTime d = firstDayOfMonth.add(Duration(days: 28));
      while (d.month == firstDayOfMonth.month) {
        d = d.add(Duration(days: 1));
        monthlyDays += 1;
      }
      monthlyDays += weekDay;
      monthlyDays += (7 - (monthlyDays % 7)) % 7;
      if (monthlyDays ~/ 7 < 6) {
        monthlyDays += 7;
      }
      List<Container> tiles = List.filled(
          monthlyDays,
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
                shape: BoxShape.rectangle, color: Colors.transparent),
          ));
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              key: containerKey,
              margin: EdgeInsets.only(right: 4, left: 4, top: 8),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor,
                      spreadRadius: -3,
                      blurRadius: 10,
                      offset: Offset(0, 0),
                    ),
                  ],
                  color: Theme.of(context).primaryColor),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    child: GridView.count(
                      padding: EdgeInsets.only(
                          top: 20, left: 16, right: 16, bottom: 16),
                      shrinkWrap: true,
                      crossAxisCount: 7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 4,
                      children: tiles,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 16, right: 16, left: 16),
                    child: Text(
                      '${date.year}年${date.month}月',
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText1?.color,
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 50),
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(),
                  )
                ],
              )),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: containerKey,
          margin: EdgeInsets.only(right: 4, left: 4, top: 8),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor,
                  spreadRadius: -3,
                  blurRadius: 10,
                  offset: Offset(0, 0),
                ),
              ],
              color: Theme.of(context).primaryColor),
          child: Stack(
            children: [
              ActivityCalender(monthlyLogs, date, habit),
              Positioned(
                top: 16,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${date.year}年${date.month}月',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyText1?.color,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class ActivityCalender extends ConsumerStatefulWidget {
  final List<List<HabitLog>?> monthlyLog;
  final DateTime date;
  final Habit habit;

  ActivityCalender(this.monthlyLog, this.date, this.habit);

  @override
  _ActivityCalenderState createState() => _ActivityCalenderState();
}

class _ActivityCalenderState extends ConsumerState<ActivityCalender> {
  @override
  Widget build(BuildContext context) {
    DateTime _t =
        DateTime.utc(widget.date.year, widget.date.month, 1).toLocal();
    List<ActivityTile> _tiles = <ActivityTile>[];
    List<DateTime> _inactive = widget.habit.isActiveDayListInMonth(_t);
    DateTime _providerTime = ref.read(_activityProvider.notifier).t;
    while (_t.month == widget.date.month) {
      List<HabitLog>? logs;
      try {
        logs = widget.monthlyLog.firstWhere(
          (dailyLogs) => dailyLogs?.first.createdAt.day == _t.day,
        );
      } on StateError {
        logs = null;
      }
      if (logs == null) {
        logs = <HabitLog>[];
      }
      bool selected = _providerTime.year == _t.year &&
          _providerTime.month == _t.month &&
          _providerTime.day == _t.day;
      _tiles.add(ActivityTile(
        logs: logs,
        day: _t,
        selected: selected,
        inactive: !(_inactive.indexWhere((time) {
              return time.day == _t.day;
            }) <
            0),
      ));
      _t = _t.add(Duration(days: 1));
    }
    List<Widget> _gridWidget = [
      ...List.filled(
          (DateTime.utc(widget.date.year, widget.date.month, 1)).weekday % 7,
          Container()),
      ..._tiles
    ];
    if (_gridWidget.length ~/ 7 < 5) {
      _gridWidget = [
        ...List.filled(
            7,
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
              ),
            )),
        ..._gridWidget
      ];
    }
    return Container(
      width: double.infinity,
      child: GridView.count(
        padding: EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 16),
        shrinkWrap: true,
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 4,
        children: _gridWidget,
      ),
    );
  }
}

class ActivityTile extends ConsumerStatefulWidget {
  final List<HabitLog> logs;
  final DateTime day;
  final bool selected;
  final bool inactive;

  ActivityTile(
      {required this.logs,
      required this.day,
      required this.inactive,
      required this.selected});

  @override
  _ActivityTileState createState() => _ActivityTileState();
}

class _ActivityTileState extends ConsumerState<ActivityTile> {
  bool selected = false;

  @override
  void initState() {
    selected = widget.selected;
    if (selected) {
      ref.read(_activityProvider.notifier).setOnOtherTap(() {
        setState(() {
          selected = false;
        });
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool did = false;
    bool hasActivity = false;
    bool today = DateTime.now().year == widget.day.year &&
        DateTime.now().month == widget.day.month &&
        DateTime.now().day == widget.day.day;
    bool isAfterToday = widget.day.isAfter(DateTime.now());
    widget.logs.forEach((log) {
      switch (log.getState()) {
        case HabitLogStateName.did:
          did = true;
          break;
        case HabitLogStateName.wannaDo:
        case HabitLogStateName.strategyChanged:
        case HabitLogStateName.aimDateOvercame:
        case HabitLogStateName.aimDateUpdated:
          hasActivity = true;
          break;
        default:
          break;
      }
    });
    if (isAfterToday || widget.inactive) {
      did = true;
    }
    return InkWell(
      onTap: widget.inactive
          ? null
          : () {
              this.selected = true;
              ref.read(_activityProvider.notifier).set(widget.logs, widget.day,
                  onOtherTap: () {
                setState(() {
                  this.selected = false;
                });
              });
              setState(() {});
            },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(shape: BoxShape.rectangle),
        child: today
            ? Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: selected
                            ? Theme.of(context).shadowColor
                            : Colors.transparent,
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                    color: Theme.of(context).colorScheme.secondary),
                alignment: Alignment.center,
                child: Text(
                  '${widget.day.day}',
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 20),
                ),
              )
            : Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasActivity
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).primaryColorDark,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selected
                          ? Theme.of(context).shadowColor
                          : Colors.transparent,
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: did
                    ? SizedBox(
                        height: 0,
                        width: 0,
                      )
                    : SvgPicture.asset(
                        'assets/icon/check.svg',
                        height: 22,
                        width: 22,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
              ),
      ),
    );
  }
}

class LogCard extends StatelessWidget {
  final List<HabitLog> logs;
  final DateTime date;
  final double maxHeight;

  LogCard(this.logs, this.date, this.maxHeight);

  @override
  Widget build(BuildContext context) {
    String date = '{month}月{day}日';
    Map<String, String> data = {
      'month': this.date.month.toString(),
      'day': this.date.day.toString(),
    };
    data.forEach((key, value) {
      date = date.replaceAll('{$key}', value);
    });
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor,
                  spreadRadius: -3,
                  blurRadius: 10,
                  offset: Offset(0, 0),
                )
              ]),
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                date,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    ?.copyWith(fontWeight: FontWeight.w700, fontSize: 20),
              ),
              SizedBox(
                height: 8,
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight - 101),
                child: logs.length > 0
                    ? ListView.builder(
                        shrinkWrap: true,
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          return Container(
                              margin: EdgeInsets.only(bottom: 4),
                              child: getSubject(logs[index], context));
                        })
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: 1,
                        itemBuilder: (context, index) {
                          return Text(
                            '・チャレンジを継続しました。',
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1
                                ?.copyWith(
                                    fontSize: 13, fontWeight: FontWeight.w400),
                          );
                        },
                      ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget getSubject(HabitLog log, BuildContext context) {
    TextStyle? _style = Theme.of(context)
        .textTheme
        .bodyText1
        ?.copyWith(fontSize: 13, fontWeight: FontWeight.w400);
    switch (log.getState()) {
      case HabitLogStateName.started:
        return Text(
          '・チャレンジを開始しました。',
          style: _style,
        );
      case HabitLogStateName.finished:
        return Text(
          '・チャレンジを終了しました。',
          style: _style,
        );
      case HabitLogStateName.strategyChanged:
        return GestureDetector(
            onTap: () {
              CreatePostArguments args = new CreatePostArguments();
              args.log = log;
              ApplicationRoutes.push(MaterialPageRoute(
                  builder: (context) => CreatePost(
                        args: args,
                      )));
            },
            child: RichText(
                text: TextSpan(text: '・', style: _style, children: [
              TextSpan(
                  text: 'ストラテジーを変更しました。',
                  style: TextStyle(decoration: TextDecoration.underline))
            ])));
      case HabitLogStateName.aimDateUpdated:
        return Text(
          '・スモールステップを更新しました。',
          style: _style,
        );
      case HabitLogStateName.aimDateOvercame:
        int step = log.getBody()['step'];
        return GestureDetector(
            onTap: () {
              CreatePostArguments args = new CreatePostArguments();
              args.log = log;
              ApplicationRoutes.push(MaterialPageRoute(
                  builder: (context) => CreatePost(
                        args: args,
                      )));
            },
            child: RichText(
                text: TextSpan(text: '・', style: _style, children: [
              TextSpan(
                  text: 'スモールステップを達成しました。($step/${Habit.getStepCount()})',
                  style: TextStyle(decoration: TextDecoration.underline))
            ])));
      case HabitLogStateName.did:
        final Map<CategoryName, String> didText = {
          CategoryName.cigarette: 'タバコを吸いました。',
          CategoryName.alcohol: 'お酒を飲みました。',
          CategoryName.sweets: 'お菓子を食べました。',
          CategoryName.sns: 'SNSを見てしまいました。',
        };
        String text = didText[log.category.name]!;
        return GestureDetector(
            onTap: () {
              ApplicationRoutes.push(MaterialPageRoute(
                  builder: (context) => DidConfirmation(log: log)));
            },
            child: RichText(
                text: TextSpan(text: '・', style: _style, children: [
              TextSpan(
                  text: text,
                  style: TextStyle(decoration: TextDecoration.underline))
            ])));
      case HabitLogStateName.wannaDo:
        final Map<CategoryName, String> wannaDoText = {
          CategoryName.cigarette: 'タバコを吸いたい気持ちを抑えました。',
          CategoryName.alcohol: 'お酒を飲みたい気持ちを抑えました。',
          CategoryName.sweets: 'お菓子を食べたい気持ちを抑えました。',
          CategoryName.sns: 'SNSを見たい気持ちを抑えました。',
        };
        String text = wannaDoText[log.category.name]!;
        return GestureDetector(
            onTap: () {
              CreatePostArguments args = new CreatePostArguments();
              args.log = log;
              ApplicationRoutes.push(MaterialPageRoute(
                  builder: (context) => CreatePost(
                        args: args,
                      )));
            },
            child: RichText(
                text: TextSpan(text: '・', style: _style, children: [
              TextSpan(
                  text: text,
                  style: TextStyle(decoration: TextDecoration.underline))
            ])));
      case HabitLogStateName.inactivate:
        return Text(
          '・チャレンジを中断しました。',
          style: _style,
        );
      case HabitLogStateName.activate:
        return Text(
          '・チャレンジを再開しました。',
          style: _style,
        );

      default:
        return SizedBox(
          height: 0,
        );
    }
  }
}
