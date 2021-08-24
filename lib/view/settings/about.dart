import '../../../library/version.dart';
import '../widgets/app-bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AboutApplication extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(context: context, titleText: ''),
      body: Container(
        color: Theme.of(context).primaryColor,
        height: double.infinity,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/brebit_icon.svg',
              height: 132,
              width: 132,
            ),
            SizedBox(
              height: 16,
            ),
            FutureBuilder(
                future: Version.isLatest(),
                builder: (context, snapshot) {
                  String message = 'バージョンを確認中';
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.data) {
                      message = '最新バージョンです';
                    } else {
                      message = 'アップデートがあります';
                    }
                  }
                  return Text(
                    'Version ${Version.version}\n$message',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).primaryColorDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w400
                    ),
                  );
                }),
            SizedBox(
              height: 24,
            ),
            InkWell(
              child: Container(
                width: 156,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: Theme.of(context).accentColor,
                    width: 1
                  ),
                  color: Theme.of(context).primaryColor
                ),
                alignment: Alignment.center,
                child: Text(
                  'アプリストアで表示',
                  style: TextStyle(
                    color: Theme.of(context).accentColor,
                    fontWeight: FontWeight.w400,
                    fontSize: 12
                  ),
                ),
              ),
              onTap: () {
                showAppStore();
              },
            ),
            SizedBox(height: 90,)
          ],
        ),
      ),
    );
  }

  void showAppStore() {
    print('show app store');
  }
}
