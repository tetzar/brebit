import 'package:brebit/provider/confetti.dart';
import 'package:brebit/view/home/widget/confetti.dart';
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
import '../../model/user.dart';
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

enum HomeActionCodes { verifyComplete }

class Home extends StatelessWidget {
  final HomeActionCodes? actionCode;

  Home(this.actionCode);

  static final GlobalKey<NavigatorState> navKey =
      new GlobalKey<NavigatorState>();

  static void pushReplacementNamed(String routeName) {
    navKey.currentState?.pushReplacementNamed(routeName);
  }

  static Future<Object?> pushNamed(String routeName, {dynamic args}) async {
    if (args != null) {
      WidgetBuilder? _builder = _routeBuildersWithArguments(routeName, args);
      if (_builder != null) {
        dynamic result = await navKey.currentState
            ?.push(MaterialPageRoute(builder: _builder));
        return result;
      }
    } else {
      dynamic result = await navKey.currentState?.pushNamed(routeName);
      return result;
    }
    return null;
  }

  static Future<Object?> push(Route route) async {
    dynamic result = navKey.currentState?.push(route);
    return result;
  }

  static void pop([dynamic result]) {
    navKey.currentState?.pop(result);
  }

  static void popUntil(String routeName) {
    navKey.currentState?.popUntil(ModalRoute.withName(routeName));
  }

  @override
  Widget build(BuildContext context) {
    return HomeNavigation(actionCode);
  }

  static WidgetBuilder? _routeBuildersWithArguments(String name, dynamic args) {
    Map<String, WidgetBuilder> _routes = {
      '/post': (context) => PostPage(args: args),
    };
    if (_routes.containsKey(name)) {
      return _routes[name];
    }
    return null;
  }

  static bool canPop() {
    return navKey.currentState?.canPop() ?? false;
  }
}

final homeTabProvider = StateNotifierProvider.autoDispose((ref) => TabState(0));

typedef HomeTabStateChangedCallback = void Function(int);

class TabState extends StateNotifier<int> {
  TabState(int state) : super(state);

  HomeTabStateChangedCallback? callback;

  void setListener(HomeTabStateChangedCallback callback) {
    this.callback = callback;
  }

  void set(int s) {
    HomeTabStateChangedCallback? callback = this.callback;
    NavigatorState? currentState = Home.navKey.currentState;
    if (callback != null &&
        s == 0 &&
        state == 0 &&
        currentState != null &&
        !currentState.canPop()) callback(state);
    state = s;
  }

  int getIndex() {
    return state;
  }
}

class HomeNavigation extends ConsumerStatefulWidget {
  final HomeActionCodes? actionCode;

  HomeNavigation(this.actionCode);

  @override
  _HomeNavigationState createState() => _HomeNavigationState();
}

class _HomeNavigationState extends ConsumerState<HomeNavigation>
    with SingleTickerProviderStateMixin {
  User? firebaseUser;
  late AnimationController _animationController;
  late Animation<double> _curve;
  late Confetti confetti;

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
    ref.read(authProvider.notifier).startNotificationListening();
    if (widget.actionCode == HomeActionCodes.verifyComplete) {
      print("start animation");
      _animationController.forward();
    }
    confetti = Confetti();
    ref.read(confettiProvider.notifier).setConfetti(confetti);
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
      child: widget.actionCode == HomeActionCodes.verifyComplete
          ? Stack(
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
                        height:
                            MediaQuery.of(context).size.height * _curve.value,
                        color: Theme.of(context).colorScheme.secondary,
                      );
                    })
              ],
            )
          : Stack(
              children: [
                Scaffold(
                    body: HomeNavigator(),
                    bottomNavigationBar: HomeBottomNavigationBar(
                      onTapped: _onItemTapped,
                    )),
                IgnorePointer(
                  child: SafeArea(child: confetti.getWidget()),
                )
              ],
            ),
    );
  }

  void _onItemTapped(int index) {
    if (index != 1) {
      ref.read(homeTabProvider.notifier).set(index);
    }
  }

  Future<bool> onWillPop() async {
    NavigatorState? currentState = Home.navKey.currentState;
    if (currentState != null && currentState.canPop()) {
      currentState.pop();
    } else {
      int index = ref.read(homeTabProvider.notifier).getIndex();
      if (index == 0) {
        SystemNavigator.pop();
      } else {
        ref.read(homeTabProvider.notifier).set(0);
      }
    }
    return false;
  }
}

class HomeBottomNavigationBar extends ConsumerStatefulWidget {
  final Function onTapped;

  HomeBottomNavigationBar({Key? key, required this.onTapped});

  @override
  _HomeBottomNavigationBarState createState() =>
      _HomeBottomNavigationBarState();
}

class _HomeBottomNavigationBarState
    extends ConsumerState<HomeBottomNavigationBar> {
  late Function _onTapped;

  @override
  void initState() {
    super.initState();
    this._onTapped = widget.onTapped;
  }

  Widget getIcon(String name) {
    return SvgPicture.asset('assets/icon/$name.svg');
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(homeTabProvider);
    int index = ref.read(homeTabProvider.notifier).getIndex();
    return BottomNavigationBar(
      showSelectedLabels: true,
      showUnselectedLabels: true,
      unselectedLabelStyle: TextStyle(height: 0, fontSize: 0),
      selectedLabelStyle: TextStyle(height: 0, fontSize: 0),
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
      Habit? habit = ref.read(homeProvider.notifier).getHabit();
      if (habit != null) {
        Navigator.pushNamed(context, '/actions');
      }
    } else {
      NavigatorState? currentState = Home.navKey.currentState;
      if (currentState != null) {
        while (currentState.canPop()) {
          currentState.pop();
        }
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
          Widget Function(BuildContext)? builder =
              routeBuilders[routeSettings.name];
          if (builder != null) {
            return MaterialPageRoute(builder: (context) => builder(context));
          }
          return MaterialPageRoute(builder: (context) => Container());
        });
  }
}

class HomeTabs extends ConsumerStatefulWidget {
  @override
  _HomeTabsState createState() => _HomeTabsState();
}

class _HomeTabsState extends ConsumerState<HomeTabs> {
  final List<Widget> _children = [
    HomeContent(),
    Text('action'),
    TimeLine(),
  ];

  final Map<int, String> _appbarTitle = {0: 'ホーム', 2: 'タイムライン'};

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    ref.watch(homeProvider);
    ref.watch(homeTabProvider);
    final index = ref.read(homeTabProvider.notifier).getIndex();
    Habit? habit = ref.read(homeProvider.notifier).getHabit();
    AuthUser? user = ref.read(authProvider.notifier).user;
    if (user == null) {
      ref.read(authProvider.notifier).getUser();
      return Scaffold(
        appBar: getMyAppBar(context: context),
        body: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'ユーザー情報を読み込んでいます',
                style: TextStyle(
                    color: Theme.of(context).disabledColor, fontSize: 24),
              ),
              SizedBox(
                height: 40,
              ),
              CircularProgressIndicator()
            ],
          ),
        ),
      );
    }
    List<Widget> actions = <Widget>[];
    if (habit != null) {
      actions.add(IconButton(
          icon: SvgPicture.asset(
            'assets/icon/search.svg',
            height: 32,
            width: 32,
          ),
          onPressed: () {
            Home.pushNamed('/search');
          }));
    }
    actions.add(RawMaterialButton(
      onPressed: () async {
        Navigator.pushNamed(context, '/profile');
      },
      child: Center(
        child: CircleAvatar(
          child: ClipOval(
            child: Stack(
              children: <Widget>[
                user.getImageWidget()

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
    ));
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: getMyAppBarTitle(_appbarTitle[index] ?? 'Brebit', context),
        leading: HookBuilder(builder: (context) {
          ref.watch(notificationProvider);
          int unreadCount = ref.read(notificationProvider.notifier).unreadCount;
          return GestureDetector(
            child: IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/notification');
                },
                icon: SvgPicture.asset(
                  unreadCount > 0
                      ? 'assets/icon/notification_marked.svg'
                      : 'assets/icon/notification_outlined.svg',
                  height: 32,
                  width: 32,
                )),
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
                  ref
                      .read(timelineProvider(friendProviderName).notifier)
                      .reloadPosts(ref);
                  ref
                      .read(timelineProvider(challengeProviderName).notifier)
                      .reloadPosts(ref);
                }
              },
              child: Icon(
                Icons.add,
              ),
              foregroundColor: Theme.of(context).primaryColor,
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.secondary,
            )
          : null,
    );
  }
}
