import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
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
  List<Strategy>? strategies;
  List<AuthUser>? users;
  List<Analysis>? analyses;

  InputFormProviderState({this.analyses, this.users, this.strategies});

  InputFormProviderState copyWith(
      {List<Analysis>? analyses,
      List<AuthUser>? users,
      List<Strategy>? strategies}) {
    return new InputFormProviderState(
      analyses: analyses == null ? this.analyses : analyses,
      strategies: strategies == null ? this.strategies : strategies,
      users: users == null ? this.users : users,
    );
  }
}

class InputFormProvider extends StateNotifier<InputFormProviderState> {
  InputFormProvider(InputFormProviderState state) : super(state);

  InputFormProviderState? recommendation;

  String word = '';

  List<AuthUser>? get users => state.users;

  List<Analysis>? get analyses => state.analyses;

  List<Strategy>? get strategies => state.strategies;

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
    List<Strategy>? _strategies = state.strategies;
    if (_strategies != null) {
      _strategies.removeWhere((existingStrategy) {
        return existingStrategy.id == strategy.id;
      });
      state = state.copyWith(strategies: _strategies);
    }
    List<Strategy>? _recommendationStrategies = recommendation?.strategies;
    if (_recommendationStrategies != null) {
      _recommendationStrategies.removeWhere((existingStrategy) {
        return existingStrategy.id == strategy.id;
      });
      recommendation =
          recommendation?.copyWith(strategies: _recommendationStrategies);
    }
  }

  void setWord(String word) {
    this.word = word;
  }

  void removeAnalysis(Analysis analysis) {
    List<Analysis>? _analyses = state.analyses;
    if (_analyses != null) {
      _analyses.removeWhere((existingAnalysis) {
        return existingAnalysis.id == analysis.id;
      });
      state = state.copyWith(analyses: _analyses);
    }
    List<Analysis>? _recommendationAnalyses = recommendation?.analyses;
    if (_recommendationAnalyses != null) {
      _recommendationAnalyses.removeWhere((existingAnalysis) {
        return existingAnalysis.id == analysis.id;
      });
      recommendation =
          recommendation?.copyWith(analyses: _recommendationAnalyses);
    }
  }
}

final recentShowProvider =
    StateNotifierProvider.autoDispose((ref) => RecentShowProvider(false));

class RecentShowProvider extends StateNotifier<bool> {
  RecentShowProvider(bool state) : super(state);

  bool get shown => state;

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

class Search extends ConsumerStatefulWidget {
  final String? args;

  Search({this.args});

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends ConsumerState<Search> {
  Timer? _timer;
  final GlobalKey<NavigatorState> _key = new GlobalKey<NavigatorState>();
  final TextEditingController _controller = new TextEditingController();
  FocusScopeNode node = new FocusScopeNode();
  late Future<List<String>> recentFuture;

  @override
  void initState() {
    ref.read(inputFormProvider.notifier).getSearchResult('');
    recentFuture = getRecent(ref.read(authProvider.notifier).user);
    var keyboardVisibilityController = KeyboardVisibilityController();
    // Subscribe
    keyboardVisibilityController.onChange.listen((bool visible) {
      if (mounted) {
        if (!visible) {
          hideRecent(ref);
        } else {
          if (_controller.text.length == 0) {
            showRecent(ref);
          }
        }
      }
    });
    super.initState();
  }

  void showRecent(WidgetRef ref) {
    ref.read(recentShowProvider.notifier).show();
  }

  void hideRecent(WidgetRef ref) {
    ref.read(recentShowProvider.notifier).hide();
  }

  @override
  Widget build(BuildContext context) {
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
                        ref.read(recentShowProvider.notifier).show();
                        return;
                      }
                    }
                    ref.read(recentShowProvider.notifier).hide();
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
                      color: Theme.of(context).textTheme.bodyText1?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    onChanged: (String text) async {
                      if (text.length > 0) {
                        ref.read(recentShowProvider.notifier).hide();
                      } else {
                        ref.read(recentShowProvider.notifier).show();
                      }
                      _timer?.cancel();
                      _timer = Timer(Duration(milliseconds: 300), () async {
                        ref.read(inputFormProvider.notifier).setWord(text);
                        try {
                          await ref
                              .read(inputFormProvider.notifier)
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
                            ref.read(authProvider.notifier).user,
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
                        color: Theme.of(context).textTheme.subtitle1?.color,
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
                  ref.read(authProvider.notifier).user, text);
              try {
                await ref
                    .read(inputFormProvider.notifier)
                    .getSearchResult(text);
              } catch (e) {
                log('debug', error: e);
              }
              ref.read(recentShowProvider.notifier).hide();
            },
            recentSearchFuture:
                getRecent(ref.read(authProvider.notifier).user)));
  }

  Future<List<String>> getRecent(AuthUser? user) async {
    if (user == null) return [];
    return await LocalManager.getRecentSearch(user);
  }
}

typedef RecentTappedCallback = Future<void> Function(String text);

class SearchFormBody extends ConsumerStatefulWidget {
  final Future<List<String>> recentSearchFuture;
  final RecentTappedCallback onRecentTapped;
  final String? initialTab;

  SearchFormBody(
      {required this.recentSearchFuture,
      required this.onRecentTapped,
      required this.initialTab});

  @override
  _SearchFormBodyState createState() =>
      _SearchFormBodyState(initialTab: initialTab);
}

class _SearchFormBodyState extends ConsumerState<SearchFormBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? initialTab;

  _SearchFormBodyState({this.initialTab});

  int initialIndex = 0;

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
    _tabController.animation?.addListener(() {
      Animation? animation = _tabController.animation;
      if (animation != null) {
        ref.read(tabProvider.notifier).set(animation.value);
      }
    });
    ref.read(tabProvider.notifier).set(initialIndex.toDouble());
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
        Consumer(
          builder: (context, ref, child) {
            ref.watch(recentShowProvider);
            bool show = ref.read(recentShowProvider.notifier).shown;
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

class RecentSearch extends ConsumerStatefulWidget {
  final List<String> list;
  final RecentTappedCallback onTap;

  RecentSearch({required this.onTap, required this.list});

  @override
  _RecentSearchState createState() => _RecentSearchState();
}

class _RecentSearchState extends ConsumerState<RecentSearch> {
  late List<String> list;

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
                color: Theme.of(context).textTheme.bodyText1?.color,
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
                        color: Theme.of(context).textTheme.bodyText1?.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 17),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    LocalManager.deleteRecentSearch(
                        ref.read(authProvider.notifier).user);
                    setState(() {
                      list = <String>[];
                    });
                  },
                  child: Text(
                    '検索履歴をクリア',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.subtitle1?.color,
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
