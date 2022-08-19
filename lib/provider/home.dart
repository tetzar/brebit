import 'package:brebit/library/exceptions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../api/habit.dart';
import '../../api/strategy.dart';
import '../../library/cache.dart';
import '../../model/habit.dart';
import '../../model/strategy.dart';
import '../../model/user.dart';

class HomeProviderState {
  Habit? habit;

  HomeProviderState({this.habit});

  HomeProviderState copyWith(Habit? habit) {
    HomeProviderState newState = new HomeProviderState(habit: habit);
    return newState;
  }
}

HomeProviderState providerState = new HomeProviderState();

final homeProvider =
    StateNotifierProvider((ref) => HomeProvider(providerState));

class HomeProvider extends StateNotifier<HomeProviderState> {
  bool _hasLoaded = false;

  HomeProvider(HomeProviderState state) : super(state);

  void updateStateWithHabit(Habit habit) {
    state = state.copyWith(habit);
  }

  void updateState({Habit? habit}) {
    state = state.copyWith(habit);
  }

  Future<Map<String, dynamic>?> getHome(AuthUser user) async {
    if (this._hasLoaded) return null;
    String? version = await LocalManager.getAnalysisVersion();
    Map<String, dynamic> result =
        await HabitApi.getHomeData(analysisVersion: version);
    await LocalManager.setAnalysisVersion(result['analysisVersion'].toString());
    Habit? habit = result['habit'];
    if (habit != null) {
      await setHabit(habit);
    }
    this._hasLoaded = true;
    return <String, dynamic>{'notificationCount': result['notificationCount']};
  }

  Future<void> suspend(Habit habit) async {
    Habit? currentHabit = state.habit;
    if (currentHabit == null) return;
    if (currentHabit.id == habit.id) {
      updateState(habit: null);
      await LocalManager.deleteHabit(habit.user);
    }
  }

  Future<void> restart(Habit habit) async {
    Habit? currentHabit = state.habit;
    if (currentHabit == null || currentHabit.id != habit.id) {
      this.setHabit(habit);
    }
  }

  Future<Map<String, List<Strategy>>> getRecommendStrategies() async {
    Habit? currentHabit = state.habit;
    if (currentHabit == null) {
      throw ProviderValueMissingException(
          "habit not found @ getRecommendedStrategies");
    }
    return await StrategyApi.getRecommendStrategies(currentHabit.category);
  }

  Future<Map<String, dynamic>> storeHabitAndGetRecommendStrategies() async {
    Habit? habit = state.habit;
    if (habit == null) {
      throw ProviderValueMissingException(
          "habit not found @storeHabitAndGetRecommendStrategies");
    }
    return await StrategyApi.storeHabitAndGetRecommendStrategies(
      habit,
    );
  }

  Future<void> setHabit(Habit habit) async {
    updateState(habit: habit);
    await LocalManager.setHabit(habit);
  }

  Habit? getHabit() {
    return state.habit;
  }

  Future<void> updateAimDate(int nextAimDate) async {
    Habit? currentHabit = state.habit;
    if (currentHabit == null) {
      throw ProviderValueMissingException(
          "habit not found @storeHabitAndGetRecommendStrategies");
    }
    Habit habit = await HabitApi.updateAimDate(currentHabit, nextAimDate);
    setHabit(habit);
  }

  Future<void> createStrategy(Map<String, dynamic> data) async {
    Habit? currentHabit = state.habit;
    if (currentHabit == null) {
      throw ProviderValueMissingException(
          "habit not found @storeHabitAndGetRecommendStrategies");
    }
    Habit habit = await StrategyApi.storeStrategy(currentHabit, data);
    setHabit(habit);
  }

  void logout() {
    this._hasLoaded = false;
    this.state.habit = null;
  }
}
