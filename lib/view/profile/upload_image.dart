import 'dart:io';

import '../../../provider/auth.dart';
import '../../../route/route.dart';
import '../general/loading.dart';
import '../widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UploadImageArguments {
  UploadImageArguments({@required this.imageFile});

  File imageFile;
}

class UploadImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    UploadImageArguments args = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      body: Container(
        child: Center(
          child: Container(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.file(
                    args.imageFile,
                    fit: BoxFit.cover,
                    width: 200,
                    height: 200,
                  ),
                ),
                TextButton(
                  child: Text('保存'),
                  onPressed: () async {
                    try {
                      MyLoading.startLoading();
                      await context
                          .read(authProvider)
                          .saveProfileImage(args.imageFile);
                      await MyLoading.dismiss();
                      ApplicationRoutes.pop();
                    } catch (e) {
                      await MyLoading.dismiss();
                      MyErrorDialog.show(e);
                    }
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
