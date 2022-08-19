import 'dart:io';

import 'package:brebit/view/general/error-widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/auth.dart';
import '../../../route/route.dart';
import '../general/loading.dart';
import '../widgets/dialog.dart';

class UploadImageArguments {
  UploadImageArguments({required this.imageFile});

  File imageFile;
}

class UploadImage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    UploadImageArguments? args = (ModalRoute.of(context)?.settings.arguments) as UploadImageArguments?;
    if (args == null) return ErrorToHomeWidget();
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
                      await ref
                          .read(authProvider.notifier)
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
