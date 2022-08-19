import 'dart:core';

import 'package:brebit/view/home/widget/confetti.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final confettiProvider = StateNotifierProvider<ConfettiProvider, bool>((ref) {
  return ConfettiProvider(false);
});


class ConfettiProvider extends StateNotifier<bool> {
  ConfettiProvider(bool state) : super(state);

  late Confetti _confetti;
  void setConfetti(Confetti confetti) {
    this._confetti = confetti;
  }

  void play() {
    _confetti.play();
  }


}
