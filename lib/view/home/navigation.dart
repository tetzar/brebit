import 'package:brebit/view/widgets/app-bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/habit.dart';
import '../../../provider/auth.dart';
import '../../../provider/home.dart';
import '../../../provider/notification.dart';
import '../../../provider/posts.dart';
import '../../../route/route.dart';
import '../notification/notification.dart';
import '../profile/profile.dart';
import '../search/search.dart';
import '../settings/about.dart';
import '../settings/account.dart';
import '../settings/account/blocking.dart';
import '../settings/account/privacy.dart';
import '../settings/account/profile.dart';
import '../settings/challenge.dart';
import '../settings/home.dart';
import '../timeline/post.dart';
import '../timeline/posts.dart';
import 'home.dart';

FirebaseAuth _auth = FirebaseAuth.instance;

enum HomeActionCodes {
  verifyComplete
}

class Home extends StatelessWidget {
  final HomeActionCodes actionCode;

  Home(this.actionCode);

  static final GlobalKey<NavigatorState> navKey =
      new GlobalKey<NavigatorState>();

  static void pushReplacementNamed(String routeName) {
    navKey.currentState.pushReplacementNamed(routeName);
  }

  static Future<dynamic> pushNamed(String routeName, {dynamic args}) async {
    if (args != null) {
      WidgetBuilder _builder = _routeBuildersWithArguments(routeName, args);
      if (_builder != null) {
        dynamic result = await navKey.currentState.push(MaterialPageRoute(
            builder: _routeBuildersWithArguments(routeName, args)));
        return result;
      }
    } else {
      dynamic result = await navKey.currentState.pushNamed(routeName);
      return result;
    }
  }

  static Future<dynamic> push(Route route) async {
    dynamic result = navKey.currentState.push(route);
    return result;
  }

  static void pop([dynamic result]) {
    navKey.currentState.pop(result);
  }

  static void popUntil(String routeName) {
    navKey.currentState.popUntil(ModalRoute.withName(routeName));
  }

  @override
  Widget build(BuildContext context) {
    return HomeNavigation(actionCode);
  }

  static WidgetBuilder _routeBuildersWithArguments(String name, dynamic args) {
    Map<String, WidgetBuilder> _routes = {
      '/post': (context) => PostPage(args: args),
    };
    if (_routes.containsKey(name)) {
      return _routes[name];
    }
    return null;
  }
}

final homeTabProvider = StateNotifierProvider.autoDispose((ref) => TabState(0));

typedef HomeTabStateChangedCallback = void Function(int);

class TabState extends StateNotifier<int> {
  TabState(int state) : super(state);

  HomeTabStateChangedCallback callback;

  void setListener(HomeTabStateChangedCallback callback) {
    this.callback = callback;
  }

  void set(int s) {
    if (callback != null && s == 0 && state == 0 && !Home.navKey.currentState.canPop()) callback(state);
    state = s;
  }
}

class HomeNavigation extends StatefulWidget {
  final HomeActionCodes actionCode;

  HomeNavigation(this.actionCode);

  @override
  _HomeNavigationState createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> with SingleTickerProviderStateMixin{
  User firebaseUser;
  AnimationController _animationController;
  Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    firebaseUser = _auth.currentUser;
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _curve = CurvedAnimation(
        parent: _animationController, curve: Curves.easeInOutQuint);
    _curve = Tween<double>(begin: 1, end: 0).animate(_curve);
    if (firebaseUser == null) {
      Navigator.popUntil(context, ModalRoute.withName('/home'));
      Navigator.pushReplacementNamed(context, '/title');
    }
    context.read(authProvider).startNotificationListening();
    if (widget.actionCode == HomeActionCodes.verifyComplete) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: widget.actionCode == HomeActionCodes.verifyComplete ? Stack(
        children: [
          Scaffold(
              body: HomeNavigator(),
              bottomNavigationBar: HomeBottomNavigationBar(
                onTapped: _onItemTapped,
              )),
          AnimatedBuilder(
              animation: _curve,
              builder: (context, child) {
                return Container(
                  height: MediaQuery.of(context).size.height * _curve.value,
                  color: Theme.of(context).accentColor,
                );
              }
          )
        ],
      ) : Scaffold(
          body: HomeNavigator(),
          bottomNavigationBar: HomeBottomNavigationBar(
            onTapped: _onItemTapped,
          )),
    );
  }

  void _onItemTapped(int index) {
    if (index != 1) {
      context.read(homeTabProvider).set(index);
    }
  }

  Future<bool> onWillPop() async {
    if (Home.navKey.currentState.canPop()) {
      Home.navKey.currentState.pop();
    } else {
      int index = context.read(homeTabProvider.state);
      if (index == 0) {
        SystemNavigator.pop();
      } else {
        context.read(homeTabProvider).set(0);
      }
    }
    return false;
  }
}

class HomeBottomNavigationBar extends StatefulHookWidget {
  final Function onTapped;

  HomeBottomNavigationBar({Key key, this.onTapped});

  @override
  _HomeBottomNavigationBarState createState() =>
      _HomeBottomNavigationBarState();
}

class _HomeBottomNavigationBarState extends State<HomeBottomNavigationBar> {
  Function _onTapped;

  @override
  void initState() {
    super.initState();
    this._onTapped = widget.onTapped;
  }

  Widget getIcon(String name) {
    return SvgPicture.asset(
        'assets/icon/$name.svg'
    );
  }

  @override
  Widget build(BuildContext context) {
    int index = useProvider(homeTabProvider.state);
    return BottomNavigationBar(
      showSelectedLabels: true,
      showUnselectedLabels: true,
      unselectedLabelStyle: TextStyle(
        height: 0,
        fontSize: 0
      ),
      selectedLabelStyle: TextStyle(
        height: 0,
        fontSize: 0
      ),
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          activeIcon: getIcon('home_filled'),
          icon: getIcon('home_outlined'),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_box_outlined),
          label: 'Actions',
        ),
        BottomNavigationBarItem(
          activeIcon: getIcon('timeline_filled'),
          icon: getIcon('timeline_outlined'),
          label: 'Timeline',
        ),
      ],
      currentIndex: index,
      onTap: (index) {
        _onItemTapped(index, context);
      },
    );
  }

  void _onItemTapped(int index, BuildContext context) {
    this._onTapped(index);
    if (index == 1) {
      Habit habit = context.read(homeProvider).getHabit();
      if (habit != null) {
        Navigator.pushNamed(context, '/actions');
      }
    } else {
      while (Home.navKey.currentState.canPop()) {
        Home.navKey.currentState.pop();
      }
    }
  }
}

Map<String, WidgetBuilder> _routeBuilders(BuildContext context) {
  return {
    '/': (context) => HomeTabs(),
    '/notification': (context) => NotificationPage(),
    '/profile': (context) => Profile(),
    '/settings': (context) => Settings(),
    '/settings/account': (context) => AccountSettings(),
    '/settings/account/profile': (context) => ProfileSetting(),
    '/settings/challenge': (context) => ChallengeSettings(),
    '/settings/about': (context) => AboutApplication(),
    '/settings/privacy': (context) => PrivacySettings(),
    '/settings/privacy/blocking': (context) => Blocking(),
    '/search': (ctx) => Search(
          args: null,
        ),
  };
}

class HomeNavigator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var routeBuilders = _routeBuilders(context);
    return Navigator(
        key: Home.navKey,
        initialRoute: '/',
        onGenerateRoute: (routeSettings) {
          return MaterialPageRoute(
              builder: (context) => routeBuilders[routeSettings.name](context));
        });
  }
}

class HomeTabs extends StatefulHookWidget {
  @override
  _HomeTabsState createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  final List<Widget> _children = [
    HomeContent(),
    Text('action'),
    TimeLine(),
  ];

  final Map<int, String> _appbarTitle = {0: 'ホーム', 2: 'タイムライン'};

  @override
  Widget build(BuildContext context) {
    useProvider(authProvider.state);
    useProvider(homeProvider.state);
    final index = useProvider(homeTabProvider.state);
    Habit habit = context.read(homeProvider).getHabit();
    List<Widget> actions = <Widget>[];
    if (habit != null) {
      actions.add(
          IconButton(
              icon: SvgPicture.asset(
                'assets/icon/search.svg',
                height: 32,
                width: 32,
              ),
              onPressed: () {
                Home.pushNamed('/search');
              })
      );
    }
    actions.add(
        RawMaterialButton(
          onPressed: () async {
            Navigator.pushNamed(context, '/profile');
          },
          child: Center(
            child: CircleAvatar(
              child: ClipOval(
                child: Stack(
                  children: <Widget>[
                    context.read(authProvider.state).user.getImageWidget()
                    /// replace y
                  ],
                ),
              ),
              radius: 16,
              // backgroundImage: NetworkImage('https://via.placeholder.com/300'),
              backgroundColor: Colors.transparent,
            ),
          ),
          shape: CircleBorder(),
        )
    );
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: getMyAppBarTitle(_appbarTitle.containsKey(index) ? _appbarTitle[index] : 'Brebit', context),
        leading: HookBuilder(builder: (context) {
          useProvider(notificationProvider.state);
          int unreadCount =
              context.read(notificationProvider).unreadCount;
          return GestureDetector(
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/notification');
              },
              icon: SvgPicture.asset(
                unreadCount > 0 ?
                'assets/icon/notification_marked.svg'
                : 'assets/icon/notification_outlined.svg',
                height: 32,
                  width: 32,
              )
            ),
          );
        }),
        actions: actions,
      ),
      body: this._children[index],
      floatingActionButton: index == 2
          ? FloatingActionButton(
              onPressed: () async {
                String result =
                    await ApplicationRoutes.pushNamed('/post/create');
                if (result == 'reload') {
                  context
                      .read(timelineProvider(friendProviderName))
                      .reloadPosts(context);
                  context
                      .read(timelineProvider(challengeProviderName))
                      .reloadPosts(context);
                }
              },
              child: Icon(
                Icons.add,
              ),
              foregroundColor: Theme.of(context).primaryColor,
              elevation: 0,
              backgroundColor: Theme.of(context).accentColor,
            )
          : null,
    );
  }
}
