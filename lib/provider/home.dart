
import '../../library/cache.dart';
import '../../model/category.dart';
import '../../model/habit.dart';
import '../../model/strategy.dart';
import '../../model/user.dart';
import '../../network/habit.dart';
import '../../network/strategy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomeProviderState {
  Habit habit;

  HomeProviderState({this.habit});

  HomeProviderState copyWith({Habit habit}) {
    HomeProviderState newState = new HomeProviderState();
    if (habit != null) {
      newState.habit = habit;
    } else {
      newState.habit = this.habit;
    }
    return newState;
  }
}

HomeProviderState providerState = new HomeProviderState();

final homeProvider =
    StateNotifierProvider((ref) => HomeProvider(providerState));

class
HomeProvider extends StateNotifier<HomeProviderState> {
  bool _hasLoaded = false;

  HomeProvider(HomeProviderState state) : super(state);

  Future<Map<String, dynamic>> getHome(AuthUser user) async {
    if (this._hasLoaded) {
      return null;
    }
    if (user == null) {
      return null;
    }
    String version = await LocalManager.getAnalysisVersion();
    Map<String, dynamic> result = await HabitApi.getHomeData(
        analysisVersion: version
    );
    await LocalManager.setAnalysisVersion(result['analysisVersion'].toString());
    Habit habit = result['habit'];
    if (habit != null) {
      await LocalManager.setHabit(habit);
      state.habit = habit;
    }
    this._hasLoaded = true;
    return <String, dynamic> {
      'notificationCount': result['notificationCount']
    };
  }

  Future<void> suspend(Habit habit) async {
    if (this.state.habit.id == habit.id) {
      state = new HomeProviderState(
        habit: null,
      );
      await LocalManager.deleteHabit(habit.user);
    }
  }
  Future<void> restart(Habit habit) async {
    if (this.state.habit == null || this.state.habit.id != habit.id) {
      this.setHabit(habit);
    }
  }

  Future<Map<String, List<Strategy>>> getRecommendStrategies() async {
    Category category = state.habit.category;
    try {
      return await StrategyApi.getRecommendStrategies(category);
    } catch (e) {
      print('error occurred in provider/home@getRecommendStrategies');
      print(e.toString());
      throw e;
    }
  }

  Future<Map<String, List<Strategy>>>
      storeHabitAndGetRecommendStrategies() async {
    try {
      return await StrategyApi.storeHabitAndGetRecommendStrategies(
        state.habit,
      );
    } catch (e) {
      print(
          'error occurred in provider/home@storeHabitAndGetRecommendStrategies');
      print(e.toString());
      throw e;
    }
  }

  void setHabit(Habit habit) async {
    state = new HomeProviderState(
      habit: habit,
    );
    await LocalManager.setHabit(habit);
  }

  Habit getHabit() {
    if (this.state == null) {
      return null;
    }
    return state.habit;
  }

  Future<void> updateAimDate(int nextAimDate) async {
    Habit habit = await HabitApi.updateAimDate(state.habit, nextAimDate);
    LocalManager.setHabit(habit);
    state = HomeProviderState(habit: habit);
  }

  Future<void> createStrategy(Map<String, dynamic> data) async {
    Habit habit = await StrategyApi.storeStrategy(
      state.habit,
      data
    );
    if (habit != null) {
      state = state.copyWith(habit: habit);
    }
  }

  void logout() {
    this._hasLoaded = false;
    this.state.habit = null;
  }
}
