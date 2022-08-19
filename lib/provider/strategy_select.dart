import '../../model/strategy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final strategySelectProvider = StateNotifierProvider(
    (ref) => StrategySelectProvider(
      StrategySelectProviderState()
    )
);

class StrategySelectProviderState {
  late List<Strategy> selectedStrategies;
  late List<Strategy> createdStrategies;
  late List<Strategy> deletedStrategies;

  StrategySelectProviderState({List<Strategy>? createdStrategies,
    List<Strategy>? deletedStrategies, List<Strategy>? selectedStrategies}) {
    this.selectedStrategies = selectedStrategies ?? [];
    this.createdStrategies = createdStrategies ?? [];
    this.deletedStrategies = deletedStrategies ?? [];
  }

  StrategySelectProviderState copy() {
    return new StrategySelectProviderState(
      selectedStrategies: this.selectedStrategies,
      createdStrategies: this.createdStrategies,
      deletedStrategies: this.deletedStrategies
    );
  }
}

class StrategySelectProvider
    extends StateNotifier<StrategySelectProviderState> {
  StrategySelectProvider(StrategySelectProviderState state) : super(state);

  void setSelected(Strategy strategy) {
    List<Strategy> selectedStrategies = state.selectedStrategies;
    selectedStrategies.add(strategy);
    state = state.copy();
  }

  void unsetSelected(Strategy strategy) {
    List<Strategy> selectedStrategies = state.selectedStrategies;
    selectedStrategies.removeWhere((selectedStrategy) =>
    selectedStrategy.id == strategy.id);
    state = state.copy();
  }

  List<Strategy> getSelected() {
    return state.selectedStrategies;
  }

  void setCreated(Strategy strategy) {
    List<Strategy> createdStrategies = state.createdStrategies;
    createdStrategies.add(strategy);
    state = state.copy();
  }

  void unsetCreated(Strategy strategy) {
    List<Strategy> createdStrategies = state.createdStrategies;
    createdStrategies.removeWhere((selectedStrategy) =>
    selectedStrategy.id == strategy.id);
    state = state.copy();
  }

  List<Strategy> getCreated() {
    return state.createdStrategies;
  }

  void setDeleted(Strategy strategy) {
    List<Strategy> deletedStrategies = state.deletedStrategies;
    deletedStrategies.add(strategy);
    state = state.copy();
  }

  List<Strategy> getDeleted() {
    return state.deletedStrategies;
  }

  void unsetDeleted(Strategy strategy) {
    state.deletedStrategies.removeWhere((selectedStrategy) =>
    selectedStrategy.id == strategy.id);
    state = state.copy();
  }

  bool isSelected(Strategy strategy) {
    List<Strategy> strategies = this.getSelected();
    for (Strategy selected in strategies) {
      if (selected.id == strategy.id) return true;
    }
    return false;
  }

  int getNextIndex() {
    List<Strategy> strategies = this.getCreated();
    int index = 1000;
    strategies.forEach((strategy) {
      int? strategyId = strategy.id;
      if (strategyId != null && strategyId < index) {
        index = strategyId;
      }
    });
    return index - 1;
  }

}