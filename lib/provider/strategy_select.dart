import '../../model/strategy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final strategySelectProvider = StateNotifierProvider(
    (ref) => StrategySelectProvider(
      StrategySelectProviderState()
    )
);

class StrategySelectProviderState {
  List<Strategy> selectedStrategies;
  List<Strategy> createdStrategies;
  List<Strategy> deletedStrategies;

  StrategySelectProviderState({this.createdStrategies,
    this.deletedStrategies, this.selectedStrategies});

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
    if (state.selectedStrategies == null) {
      state.selectedStrategies = <Strategy>[];
    }
    state.selectedStrategies.add(strategy);
    state = state.copy();
  }

  void unsetSelected(Strategy strategy) {
    state.selectedStrategies.removeWhere((selectedStrategy) =>
    selectedStrategy.id == strategy.id);
    state = state.copy();
  }

  List<Strategy> getSelected() {
    if (state.selectedStrategies == null) {
      return <Strategy>[];
    }
    return state.selectedStrategies;
  }

  void setCreated(Strategy strategy) {
    if (state.createdStrategies == null) {
      state.createdStrategies = <Strategy>[];
    }
    state.createdStrategies.add(strategy);
    state = state.copy();
  }

  void unsetCreated(Strategy strategy) {
    state.createdStrategies.removeWhere((selectedStrategy) =>
    selectedStrategy.id == strategy.id);
    state = state.copy();
  }

  List<Strategy> getCreated() {
    if (state.createdStrategies == null) {
      return <Strategy>[];
    }
    return state.createdStrategies;
  }

  void setDeleted(Strategy strategy) {
    if (state.deletedStrategies == null) {
      state.deletedStrategies = <Strategy>[];
    }
    state.deletedStrategies.add(strategy);
    state = state.copy();
  }

  List<Strategy> getDeleted() {
    if (state.deletedStrategies == null) {
      return <Strategy>[];
    }
    return state.deletedStrategies;
  }

  void unsetDeleted(Strategy strategy) {
    state.deletedStrategies.removeWhere((selectedStrategy) =>
    selectedStrategy.id == strategy.id);
    state = state.copy();
  }

  bool isSelected(Strategy strategy) {
    List<Strategy> strategies = this.getSelected();
    strategies.forEach((selectedStrategy) {
      if (selectedStrategy.id == strategy.id) {
        return true;
      }
    });
    return false;
  }

  int getNextIndex() {
    List<Strategy> strategies = this.getCreated();
    int index = 1000;
    strategies.forEach((strategy) {
      if (strategy.id < index) {
        index = strategy.id;
      }
    });
    return index - 1;
  }

}