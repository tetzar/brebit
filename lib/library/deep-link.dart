
//
// import 'package:uni_links/uni_links.dart';
//
// class DeepLinkManager {
//   static StreamSubscription _subLink;
//   static StreamSubscription _subUrl;
//
//   static Future<void> init() async {
//     print('start linking');
//     _subLink = linkStream.listen((String link) {
//       // Parse the link and warn the user, if it is not correct
//       print(link);
//     }, onError: (err) {
//       // Handle exception by warning the user their action did not succeed
//     });
//     _subUrl = uriLinkStream.listen((Uri uri) {
//       print(uri.path);
//     }, onError: (e) {
//
//     });
//
//   }
// }