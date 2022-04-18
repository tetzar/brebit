import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../api/search.dart';
import '../../../library/cache.dart';
import '../../../model/analysis.dart';
import '../../../model/strategy.dart';
import '../../../model/user.dart';
import '../../../provider/auth.dart';
import 'account.dart';
import 'analysis.dart';
import 'search-slider.dart';
import 'strategy.dart';

final inputFormProvider = StateNotifierProvider.autoDispose(
    (ref) => InputFormProvider(new InputFormProviderState()));

class InputFormProviderState {
  List<Strategy> strategies;
  List<AuthUser> users;
  List<Analysis> analyses;

  InputFormProviderState({this.analyses, this.users, this.strategies});

  InputFormProviderState copyWith(
      {List<Analysis> analyses,
      List<AuthUser> users,
      List<Strategy> strategies}) {
    return new InputFormProviderState(
      analyses: analyses == null ? this.analyses : analyses,
      strategies: strategies == null ? this.strategies : strategies,
      users: users == null ? this.users : users,
    );
  }
}

class InputFormProvider extends StateNotifier<InputFormProviderState> {
  InputFormProvider(InputFormProviderState state) : super(state);

  InputFormProviderState recommendation;

  String word = '';

  Future<void> getSearchResult(String text) async {
    if (text.length == 0) {
      if (recommendation == null) {
        Map<String, dynamic> result = await SearchApi.getSearchResult('_');
        recommendation = InputFormProviderState(
            analyses: result['analyses'],
            users: result['users'],
            strategies: result['strategies']);
      }
      state = new InputFormProviderState(
        strategies: <Strategy>[],
        users: <AuthUser>[],
        analyses: <Analysis>[],
      );
    } else {
      List<String> splitHalf = text.split(' ');
      List<String> splitFull = <String>[];
      splitHalf.forEach((t) {
        splitFull.addAll(t.split('　'));
      });
      String data = '_';
      splitFull.forEach((t) {
        data += t + '_';
      });
      Map<String, dynamic> result = await SearchApi.getSearchResult(data);
      state = InputFormProviderState(
          analyses: result['analyses'],
          users: result['users'],
          strategies: result['strategies']);
    }
  }

  void removeStrategy(Strategy strategy) {
    List<Strategy> _strategies = state.strategies;
    _strategies.removeWhere((existingStrategy) {
      return existingStrategy.id == strategy.id;
    });
    List<Strategy> _recommendationStrategies = recommendation.strategies;
    _recommendationStrategies.removeWhere((existingStrategy) {
      return existingStrategy.id == strategy.id;
    });
    recommendation =
        recommendation.copyWith(strategies: _recommendationStrategies);
    state = state.copyWith(strategies: _strategies);
  }

  void setWord(String word) {
    this.word = word;
  }

  void removeAnalysis(Analysis analysis) {
    List<Analysis> _analyses = state.analyses;
    _analyses.removeWhere((existingAnalysis) {
      return existingAnalysis.id == analysis.id;
    });
    List<Analysis> _recommendationAnalyses = recommendation.analyses;
    _recommendationAnalyses.removeWhere((existingAnalysis) {
      return existingAnalysis.id == analysis.id;
    });
    recommendation = recommendation.copyWith(analyses: _recommendationAnalyses);
    state = state.copyWith(analyses: _analyses);
  }
}

final recentShowProvider =
    StateNotifierProvider.autoDispose((ref) => RecentShowProvider(false));

class RecentShowProvider extends StateNotifier<bool> {
  RecentShowProvider(bool state) : super(state);

  void hide() {
    if (state) {
      state = false;
    }
  }

  void show() {
    if (!state) {
      state = true;
    }
  }
}

class Search extends StatefulWidget {
  final String args;

  Search({@required this.args});

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  Timer _timer;
  final GlobalKey<NavigatorState> _key = new GlobalKey<NavigatorState>();
  final TextEditingController _controller = new TextEditingController();
  FocusScopeNode node = new FocusScopeNode();
  Future<List<String>> recentFuture;

  BuildContext _ctx;

  @override
  void initState() {
    context.read(inputFormProvider).getSearchResult('');
    recentFuture = getRecent(context.read(authProvider.state).user);
    var keyboardVisibilityController = KeyboardVisibilityController();
    // Subscribe
    keyboardVisibilityController.onChange.listen((bool visible) {
      if (mounted) {
        if (!visible) {
          hideRecent();
        } else {
          if (_controller.text.length == 0) {
            showRecent();
          }
        }
      }
    });
    super.initState();
  }

  void showRecent() {
    _ctx.read(recentShowProvider).show();
  }

  void hideRecent() {
    _ctx.read(recentShowProvider).hide();
  }

  @override
  Widget build(BuildContext context) {
    _ctx = context;
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Container(
            padding: EdgeInsets.only(
              left: 24,
            ),
            child: Container(
              height: 39,
              child: FocusScope(
                node: node,
                child: Focus(
                  onFocusChange: (bool focused) {
                    if (focused) {
                      if (_controller.text.length == 0) {
                        context.read(recentShowProvider).show();
                        return;
                      }
                    }
                    context.read(recentShowProvider).hide();
                  },
                  child: TextFormField(
                    key: _key,
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: '検索',
                      hintStyle: TextStyle(
                          color: Theme.of(context).disabledColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w400),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyText1.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    onChanged: (String text) async {
                      if (text.length > 0) {
                        context.read(recentShowProvider).hide();
                      } else {
                        context.read(recentShowProvider).show();
                      }
                      _timer?.cancel();
                      _timer = Timer(Duration(milliseconds: 300), () async {
                        context.read(inputFormProvider).setWord(text);
                        try {
                          await context
                              .read(inputFormProvider)
                              .getSearchResult(text);
                        } catch (e) {
                          log('debug', error: e);
                        }
                      });
                    },
                    onEditingComplete: () async {
                      FocusScope.of(context).unfocus();
                      String text = _controller.text;
                      if (text.length > 0) {
                        await LocalManager.setRecentSearch(
                            context.read(authProvider.state).user,
                            _controller.text);
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Container(
                  margin: EdgeInsets.only(right: 24),
                  height: double.infinity,
                  alignment: Alignment.center,
                  child: Text(
                    'キャンセル',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.subtitle1.color,
                        fontWeight: FontWeight.w400,
                        fontSize: 10),
                  ),
                ))
          ],
          titleSpacing: 0,
        ),
        body: SearchFormBody(
            initialTab: widget.args,
            onRecentTapped: (String text) async {
              _controller.text = text;
              _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length));
              node.unfocus();
              LocalManager.setRecentSearch(
                  context.read(authProvider.state).user, text);
              try {
                await context.read(inputFormProvider).getSearchResult(text);
              } catch (e) {
                log('debug', error: e);
              }
              context.read(recentShowProvider).hide();
            },
            recentSearchFuture:
                getRecent(context.read(authProvider.state).user)));
  }

  Future<List<String>> getRecent(AuthUser user) async {
    return await LocalManager.getRecentSearch(user);
  }
}

typedef RecentTappedCallback = Future<void> Function(String text);

class SearchFormBody extends StatefulWidget {
  final Future<List<String>> recentSearchFuture;
  final RecentTappedCallback onRecentTapped;
  final String initialTab;

  SearchFormBody(
      {@required this.recentSearchFuture,
      @required this.onRecentTapped,
      @required this.initialTab});

  @override
  _SearchFormBodyState createState() =>
      _SearchFormBodyState(initialTab: initialTab);
}

class _SearchFormBodyState extends State<SearchFormBody>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  final String initialTab;

  _SearchFormBodyState({@required this.initialTab});

  int initialIndex;

  @override
  void initState() {
    initialIndex = 0;
    if (initialTab != null) {
      switch (initialTab) {
        case 'strategy':
          initialIndex = 1;
          break;
        case 'analysis':
          initialIndex = 2;
          break;
        default:
          break;
      }
    }
    _tabController =
        new TabController(length: 3, vsync: this, initialIndex: initialIndex);
    _tabController.animation.addListener(() {
      context.read(tabProvider).set(_tabController.animation.value);
    });
    context.read(tabProvider).set(initialIndex.toDouble());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          color: Theme.of(context).primaryColor,
          child: Column(
            children: [
              SearchTabBarContent(tabController: _tabController),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    AccountResult(),
                    StrategyResult(),
                    AnalysisResult(),
                  ],
                ),
              )
            ],
          ),
        ),
        HookBuilder(
          builder: (BuildContext context) {
            bool show = useProvider(recentShowProvider.state);
            if (show) {
              return FutureBuilder(
                future: widget.recentSearchFuture,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(),
                    );
                  }
                  return RecentSearch(
                      list: snapshot.data, onTap: widget.onRecentTapped);
                },
              );
            } else {
              return Container(
                height: 0,
                width: 0,
              );
            }
          },
        )
      ],
    );
  }
}

class RecentSearch extends StatefulWidget {
  final List<String> list;
  final RecentTappedCallback onTap;

  RecentSearch({@required this.onTap, @required this.list});

  @override
  _RecentSearchState createState() => _RecentSearchState();
}

class _RecentSearchState extends State<RecentSearch> {
  List<String> list;

  @override
  void initState() {
    list = widget.list;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> cards = <Widget>[];
    list.reversed.forEach((word) {
      cards.add(InkWell(
        onTap: () async {
          await widget.onTap(word);
        },
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(vertical: 5),
          alignment: Alignment.centerLeft,
          child: Text(
            word,
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyText1.color,
                fontSize: 15,
                fontWeight: FontWeight.w400),
          ),
        ),
      ));
    });
    return Container(
      color: Theme.of(context).primaryColor,
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.only(top: 3, left: 24, right: 24),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    '最近の検索',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyText1.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 17),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    LocalManager.deleteRecentSearch(
                        context.read(authProvider.state).user);
                    setState(() {
                      list = <String>[];
                    });
                  },
                  child: Text(
                    '検索履歴をクリア',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.subtitle1.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w400),
                  ),
                )
              ],
            ),
            Column(children: cards)
          ],
        ),
      ),
    );
  }
}
