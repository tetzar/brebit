import 'package:flutter_easyloading/flutter_easyloading.dart';

class MyLoading {
  static void initialize() {
    EasyLoading.init();
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 1500)
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle = EasyLoadingStyle.light
      ..indicatorSize = 45.0
      ..radius = 8.0
      ..dismissOnTap = false;
  }

  static Future<void> startLoading() async {
    await EasyLoading.show(
      status: 'loading...',
      maskType: EasyLoadingMaskType.black,
    );
  }

  static Future<void> dismiss() async {
    await EasyLoading.dismiss();
  }
}
