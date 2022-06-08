import '../../model/tag.dart';
import '../../api/habit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final conditionProvider =
    StateNotifierProvider.autoDispose((ref) => ConditionProvider(<Tag>[]));

class ConditionProvider extends StateNotifier<List<Tag>> {
  ConditionProvider(List<Tag> state) : super(state);

  void setList(List<Tag> tags) {
    while (state.length > 0) {
      state.removeLast();
    }
    state.addAll(tags);
  }

  void setToList(Tag condition) {
    if (!this.isSet(condition.name)) {
      state = state..add(condition);
    }
  }

  void unsetFromList(Tag condition) {
    if (this.isSet(condition.name)) {
      state = state..remove(condition);
    }
  }

  bool isSet(String condition) {
    return state.where((tag) => tag.name == condition).length > 0;
  }

  bool hasData() {
    return this.state.length > 0;
  }

  bool hasChanged(List<Tag> initialSelected) {
    bool changed = false;
    if (this.state.length == 0 && initialSelected.length == 0) {
      return false;
    }
    if (this.state.length == initialSelected.length) {
      initialSelected.forEach((tag) {
        print(tag.name);
        if (!changed && this.state.indexWhere((t) => t.name == tag.name) < 0) {
          changed = true;
        }
      });
    } else {
      return true;
    }
    return changed;
  }

  List<Tag> getList() {
    return this.state;
  }
}

final circumstanceSuggestionProvider =
    StateNotifierProvider((ref) => CircumstanceSuggestionProvider(<Tag>[]));

class CircumstanceSuggestionProvider extends StateNotifier<List<Tag>> {
  CircumstanceSuggestionProvider(List<Tag> state) : super(state);

  List<Tag> recommendations = <Tag>[];

  void initialize() {
    while(state.length > 0) {
      state.removeLast();
    }
  }

  void setTags(List<Tag> tags) {
    state = tags;
  }

  void setRecommendation() {
    state = recommendations;
  }

  bool isSet(String text) {
   return ! (state.indexWhere((tag) => tag.name == text) < 0);
  }

  List<Tag> getTags() {
    return state;
  }

  Future<void> getSuggestions(String text) async {
    Map<String, dynamic> result = await HabitApi.getConditionSuggestions(text);
    List<Tag> suggestions = result['tags'];
    Tag inputTag = result['hit'];
    if (text.length == 0) {
      recommendations = suggestions;
    }
    if (inputTag != null) {
      suggestions.insert(0, inputTag);
    }
    this.state = suggestions;
  }
}

class MentalValue{

  static List<MentalValue> mentalValues = [
    MentalValue(
        id: 'stress',
        name: 'ストレス',
      picturePath: 'assets/icon/stress.svg'
    ),
    MentalValue(
        id: 'loneliness',
        name: '孤独',
        picturePath: 'assets/icon/loneliness.svg'
    ),
    MentalValue(
        id: 'happiness',
        name: '幸せ',
        picturePath: 'assets/icon/happiness.svg'
    ),
    MentalValue(
        id: 'boring',
        name: '退屈',
        picturePath: 'assets/icon/boring.svg'
    ),
    MentalValue(
        id: 'excited',
        name: '興奮',
        picturePath: 'assets/icon/excited.svg'
    ),
    MentalValue(
        id: 'melancholy',
        name: '憂鬱',
        picturePath: 'assets/icon/melancholy.svg'
    ),
    MentalValue(
        id: 'angry',
        name: 'イライラ',
        picturePath: 'assets/icon/angry.svg'
    ),
    MentalValue(
        id: 'anxiety',
        name: '孤独',
        picturePath: 'assets/icon/anxiety.svg'
    ),
  ];

  String id;
  String name;
  String picturePath;

  MentalValue({this.id, this.name, this.picturePath});

  static MentalValue find(String id){
    return mentalValues.firstWhere((val) => val.id == id);
  }
}

final conditionValueProvider = StateNotifierProvider.autoDispose(
        (ref) => ConditionValueProvider(new ConditionValueState()));

class ConditionValueState {
  double desire = 0;
  MentalValue mental;
  List<Tag> tags = <Tag>[];

  ConditionValueState({this.desire, this.mental, this.tags});

  ConditionValueState copyWith(
      {double desire, MentalValue mental, List<Tag> tags}) {
    return ConditionValueState(
        desire: desire != null ? desire : this.desire,
        mental: mental != null ? mental : this.mental,
        tags: tags != null ? tags : this.tags);
  }

  void initialize() {
    this.desire = 0;
    this.mental = null;
    this.tags = <Tag>[];
  }
}


class ConditionValueProvider extends StateNotifier<ConditionValueState> {
  ConditionValueProvider(ConditionValueState state) : super(state);

  void initialize() {
    this.state.initialize();
  }

  void setDesire(double num) {
    this.state = state.copyWith(desire: num);
  }

  void setMental(MentalValue m) {
    this.state = state.copyWith(mental: m);
  }

  bool mentalIs(MentalValue m) {
    if (this.state.mental == null) {
      return false;
    }
    return this.state.mental.id == m.id;
  }

  void setTags(List<Tag> t) {
    this.state = state.copyWith(tags: t);
  }

  bool isTagsSet() {
    return this.state.tags.length > 0;
  }

  void removeTag(Tag tag) {
    state = state..tags.removeWhere((t) => tag.name == t.name);
  }

  bool savable() {
    return (state.desire > 0 &&
        state.mental != null &&
        state.tags.length > 0);
  }
}