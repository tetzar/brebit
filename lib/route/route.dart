import 'package:brebit/library/exceptions.dart';
import 'package:brebit/main.dart';
import 'package:brebit/model/habit_log.dart';
import '../view/action/actions.dart';
import '../view/action/circumstance.dart';
import '../view/action/did/check-amount.dart';
import '../view/action/did/check_strategy.dart';
import '../view/action/did/condition.dart';
import '../view/action/did/confirmation.dart';
import '../view/action/endured/condition.dart';
import '../view/action/endured/confirmation.dart';
import '../view/action/endured/executed_strategy.dart';
import '../view/action/want/condition.dart';
import '../view/action/want/execute_strategy.dart';
import '../view/action/want/confirmation.dart';
import '../view/general/explanation/small-step.dart';
import '../view/general/explanation/strategy.dart';
import '../view/habit/information/alcohol.dart';
import '../view/habit/information/cigarette.dart';
import '../view/habit/information/sns.dart';
import '../view/habit/information/sweets.dart';
import '../view/habit/select-strategy.dart';
import '../view/home/navigation.dart';
import '../view/home/small-step.dart';
import '../view/notification/notification.dart';
import '../view/profile/upload_image.dart';
import '../view/profile/widgets/profile-image-select.dart';
import '../view/settings/account/email.dart';
import '../view/settings/account/password.dart';
import '../view/settings/account/user-name.dart';
import '../view/start/home.dart';
import '../view/start/password-reset.dart';
import '../view/start/send-verification.dart';
import '../view/strategy/create.dart';
import '../view/start/introduction.dart';
import '../view/start/login.dart';
import '../view/start/register.dart';
import '../view/habit/start_habit.dart';
import '../view/timeline/create_post.dart';
import '../view/timeline/post.dart';
import 'package:flutter/material.dart';
import '../view/start/title.dart' as ViewTitle;

class ApplicationRoutes {
  static GlobalKey<NavigatorState> materialKey =
      new GlobalKey<NavigatorState>();

  static dynamic push(Route route) {
    NavigatorState? currentState = materialKey.currentState;
    if (currentState == null) return;
    var result = currentState.push(route);
    return result;
  }

  static Future<dynamic> pushNamed(String routeName, [dynamic arguments]) async {
    NavigatorState? currentState = materialKey.currentState;
    if (currentState == null) return;
    var result;
    result = await currentState.pushNamed(routeName, arguments: arguments);
    return result;
  }


  static Future<dynamic> pushReplacement(Route route, {dynamic arguments}) async {
    NavigatorState? currentState = materialKey.currentState;
    if (currentState == null) return;
    return await pushReplacement(
      route,
      arguments: arguments
    );
  }

  static Future<dynamic> pushReplacementNamed(String routeName, {dynamic arguments}) async{
    NavigatorState? currentState = materialKey.currentState;
    if (currentState == null) return;
    var result;
    result = await currentState.pushReplacementNamed(routeName, arguments: arguments);
    return result;
  }

  static void pop([dynamic result]) {
    NavigatorState? currentState = materialKey.currentState;
    if (currentState == null) return;
    currentState.pop(result);
  }

  static void popUntil(routeName) {
    NavigatorState? currentState = materialKey.currentState;
    if (currentState == null) return;
    currentState.popUntil(ModalRoute.withName(routeName));
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    Map<String, WidgetBuilder> routes = ApplicationRoutes.getRoutes();
    String? route = settings.name;
    if (route != null && routes.containsKey(route)) {
      return MaterialPageRoute(builder: routes[route]!, settings: settings);
    } else {
      throw RouteNotFoundException("route not found in generate Route: $route}");
    }
  }

  static Map<String, WidgetBuilder> getRoutes() {
    Map<String, WidgetBuilder> routes = {
      '/': (context) => ApplicationHome(),
      '/splash': (context) => Splash(),
      '/title': (context) => ViewTitle.Title(),
      '/introduction': (context) => Introduction(),
      '/register': (context) => Registration(
        ModalRoute.of(context)!.settings.arguments as Map<String, String>
      ),
      '/login': (context) => Login(
        email: ModalRoute.of(context)!.settings.arguments as String?,
      ),
      '/password-reset': (context) => PasswordReset(),
      '/password-reset/sent': (context) => PasswordResetSend(
        ModalRoute.of(context)!.settings.arguments as String
      ),
      '/email-verify': (context) => SendVerificationCodeScreen(
        ModalRoute.of(context)!.settings.arguments as String
      ),
      '/home': (context) => Home(
        ModalRoute.of(context)!.settings.arguments as HomeActionCodes?
      ),
      '/home/small-step': (context) => SmallStep(),
      '/notification': (context) => NotificationPage(),
      '/startHabit': (context) => StartHabit(),
      '/category/cigarette': (context) => CigaretteInformation(),
      '/category/alcohol': (context) => AlcoholInformation(),
      '/category/sweets': (context) => SweetsInformation(),
      '/category/sns': (context) => SNSInformation(),
      '/actions': (context) => HabitActions(),
      '/strategy/create': (context) => StrategyCreate(
        params: ModalRoute.of(context)!.settings.arguments as StrategyCreateParams,
      ),
      '/strategy/select': (context) => SelectStrategy(
        params: ModalRoute.of(context)!.settings.arguments as SelectStrategyParams,
      ),
      '/post': (context) =>
          PostPage(args: ModalRoute.of(context)!.settings.arguments as PostArguments),
      '/post/create': (context) => CreatePost(
        args: ModalRoute.of(context)!.settings.arguments as CreatePostArguments,
      ),
      '/profile/image': (context) => ProfileImageSelect(),
      '/profile/image/upload': (context) => UploadImage(),
      '/want/condition': (context) => ConditionWanna(),
      '/want/strategy/index': (context) => ExecuteStrategyWanna(
        params: ModalRoute.of(context)!.settings.arguments as ExecuteStrategyWannaParam
      ),
      '/want/confirmation': (context) => WantConfirmation(
        args: ModalRoute.of(context)!.settings.arguments as WantConfirmationArguments,
      ),
      '/did/condition': (context) => ConditionDid(),
      '/did/used-amount': (context) => CheckAmount(
        checkedValue: ModalRoute.of(context)!.settings.arguments as CheckedValue,
      ),
      "/circumstance": (context) => Circumstance(
        params: ModalRoute.of(context)!.settings.arguments as CircumstanceParams,
      ),
      "/did/strategy/index": (context) => CheckStrategyDid(),
      '/did/confirmation': (context) => DidConfirmation(
        log: ModalRoute.of(context)!.settings.arguments as HabitLog,
      ),
      '/endured/condition': (context) => ConditionEndured(),
      "/endured/strategy/index": (context) => CheckStrategyEndured(),
      '/endured/confirmation': (context) => EnduredConfirmation(),
      '/explanation/strategy': (context) => StrategyExplanation(),
      '/explanation/small-step': (context) => SmallStepExplanation(),
      '/settings/account/customId': (context) => CustomIdForm(),
      '/settings/account/email': (context) => EmailSetting(),
      '/settings/account/email/register/complete': (context) => EmailRegisterComplete(
        ModalRoute.of(context)!.settings.arguments as String
      ),
      '/settings/account/email/change/complete': (context) => EmailRegisterComplete(
          ModalRoute.of(context)!.settings.arguments as String
      ),
      '/settings/account/password': (context) => ChangePassword(),
      '/settings/account/password/complete': (context) => PasswordChangeComplete(),
    };
    return routes;
  }

}
