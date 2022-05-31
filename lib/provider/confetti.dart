import 'dart:core';

import 'package:brebit/view/home/widget/confetti.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final confettiProvider = StateNotifierProvider<ConfettiProvider>((ref) {
  return ConfettiProvider(false);
});


class ConfettiProvider extends StateNotifier<bool> {
  ConfettiProvider(bool state) : super(state);

  Confetti _confetti;
  void setConfetti(Confetti confetti) {
    this._confetti = confetti;
  }

  void play() {
    _confetti.play();
  }


}
