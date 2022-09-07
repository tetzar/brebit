import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../model/image.dart' as ImageModel;
import '../../../../model/user.dart';
import '../../../../provider/auth.dart';
import '../../../../route/route.dart';
import '../../general/image-crop.dart';
import '../../general/loading.dart';
import '../../widgets/back-button.dart';
import '../../widgets/bottom-sheet.dart';
import '../../widgets/dialog.dart';

class ProfileImageSelect extends ConsumerStatefulWidget {
  @override
  _ProfileImageSelectState createState() => _ProfileImageSelectState();
}

class _ProfileImageSelectState extends ConsumerState<ProfileImageSelect> {
  File? imageFile;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    AuthUser? user = ref.read(authProvider.notifier).user;
    File? imageFile = this.imageFile;
    return WillPopScope(
      onWillPop: () {
        return onWillPop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('プロフィール画像'),
          centerTitle: true,
          leading: MyBackButtonX(
            onPressed: () {
              if (imageFile != null) {
                showCancelDialog(context);
              } else {
                ApplicationRoutes.pop();
              }
            },
          ),
          actions: [
            IconButton(
                icon: Icon(Icons.check,
                    color: imageFile != null
                        ? Theme.of(context).appBarTheme.iconTheme?.color
                        : Theme.of(context).disabledColor),
                onPressed: imageFile != null
                    ? () async {
                        await saveImage(context);
                      }
                    : null)
          ],
        ),
        body: Container(
          color: Theme.of(context).primaryColor,
          padding: EdgeInsets.only(top: 80),
          width: MediaQuery.of(context).size.width,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                child: ClipOval(
                  child: Container(
                    width: 200,
                    height: 200,
                    child: imageFile != null
                        ? Image.file(
                            imageFile,
                            fit: BoxFit.cover,
                            width: 200,
                            height: 200,
                          )
                        : user?.getImageWidget() ?? AuthUser.getDefaultImage(),
                  ),
                ),
                radius: 100,
                // backgroundImage: NetworkImage('https://via.placeholder.com/300'),
                backgroundColor: Colors.transparent,
              ),
              Container(
                margin: EdgeInsets.only(top: 24),
                child: TextButton(
                  onPressed: () {
                    showOptions(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(17)),
                        color: Theme.of(context).colorScheme.secondary),
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                    width: 96,
                    height: 34,
                    child: Text(
                      '変更する',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> onWillPop(BuildContext ctx) async {
    if (this.imageFile != null) {
      showCancelDialog(ctx);
    } else {
      ApplicationRoutes.pop();
    }
    return false;
  }

  void showCancelDialog(BuildContext ctx) {
    showDialog(
        context: ctx,
        builder: (_) {
          return AlertDialog(
            content: Text('変更を破棄しますか？'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ApplicationRoutes.pop();
                  },
                  child: Text('はい')),
              TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  child: Text('いいえ'))
            ],
          );
        });
  }

  Future<void> saveImage(BuildContext context) async {
    try {
      MyLoading.startLoading();
      File? imageFile = this.imageFile;
      if (imageFile != null) {
        imageFile = await ImageModel.Image.resizeImage(imageFile);
        await ref.read(authProvider.notifier).saveProfileImage(imageFile);
      }
      await MyLoading.dismiss();
      ApplicationRoutes.pop();
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }

  void showOptions(BuildContext ctx) {
    List<BottomSheetItem> _items = [
      NormalBottomSheetItem(
          context: context,
          text: '画像を選ぶ',
          onSelect: () async {
            ApplicationRoutes.pop();
            File? file = await _selectImageFromGallery();
            if (file != null) {
              File? croppedImage = await MyImageCropper.cropImage(context, file);
              if (croppedImage == null) return;
              imageFile = croppedImage;
              setState(() {});
            }
          }),
      NormalBottomSheetItem(
        context: context,
        text: '写真を撮る',
        onSelect: () async {
          ApplicationRoutes.pop();
          File? file = await _takePhoto();
          if (file != null) {
            imageFile = await MyImageCropper.cropImage(context, file);
            setState(() {});
          }
        },
      )
    ];
    bool imageDeletable =
        ref.read(authProvider.notifier).user?.hasImage() ?? false || imageFile != null;
    if (imageDeletable) {
      _items.add(CautionBottomSheetItem(
          context: context,
          text: '現在の画像を削除',
          onSelect: () {
            ApplicationRoutes.pop();
            imageFile = null;
            setState(() {});
          }));
    }
    _items.add(CancelBottomSheetItem(
        context: context,
        onSelect: () {
          ApplicationRoutes.pop();
        }));
    showCustomBottomSheet(
        items: _items,
        backGroundColor: Theme.of(context).primaryColor,
        context: ApplicationRoutes.materialKey.currentContext ?? context);
  }

  Future<File?> _takePhoto() async {
    final picker = ImagePicker();
    // bool cameraGranted = await Permission.camera.request() == PermissionStatus.granted;
    bool cameraGranted = true;
    if (cameraGranted) {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    }
    return null;
  }

  Future<File?> _selectImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      print('image not selected');
      return null;
    }
  }
}
