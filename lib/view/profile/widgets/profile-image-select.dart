import 'dart:io';

import '../../../../model/image.dart' as ImageModel;
import '../../../../model/user.dart';
import '../../../../provider/auth.dart';
import '../../../../route/route.dart';
import '../../general/image-crop.dart';
import '../../general/loading.dart';
import '../../widgets/back-button.dart';
import '../../widgets/bottom-sheet.dart';
import '../../widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageSelect extends StatefulHookWidget {
  @override
  _ProfileImageSelectState createState() => _ProfileImageSelectState();
}

class _ProfileImageSelectState extends State<ProfileImageSelect> {
  File imageFile;
  bool _hasChanged;

  @override
  void initState() {
    _hasChanged = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AuthProviderState _authProviderState = useProvider(authProvider.state);
    AuthUser user = _authProviderState.user;
    return WillPopScope(
      onWillPop: () {
        return onWillPop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('プロフィール画像'),
          centerTitle: true,
          leading: MyBackButtonX(
            onPressed:  () {
              if (_hasChanged) {
                showCancelDialog(context);
              } else {
                ApplicationRoutes.pop();
              }
            },
          ),
          actions: [
            IconButton(
                icon: Icon(Icons.check,
                    color: _hasChanged
                        ? Theme.of(context).appBarTheme.iconTheme.color
                        : Theme.of(context).disabledColor),
                onPressed: _hasChanged
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
                    child: _hasChanged
                        ? Image.file(
                            imageFile,
                            fit: BoxFit.cover,
                            width: 200,
                            height: 200,
                          )
                        : user.getImageWidget(),
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
                        color: Theme.of(context).accentColor),
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
      imageFile = await ImageModel.Image.resizeImage(imageFile);
      await context.read(authProvider).saveProfileImage(imageFile);
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
            File file = await _selectImageFromGallery();
            if (file != null) {
              imageFile = await MyImageCropper.cropImage(context, file);
              _hasChanged = true;
              setState(() {});
            }
          }),
      NormalBottomSheetItem(
        context: context,
        text: '写真を撮る',
        onSelect: () async {
          ApplicationRoutes.pop();
          File file = await _takePhoto();
          if (file != null) {
            imageFile = await MyImageCropper.cropImage(context, file);
            _hasChanged = true;
            setState(() {});
          }
        },
      )
    ];
    bool imageDeletable = context.read(authProvider.state).user.hasImage() ||
    imageFile != null;
    if (imageDeletable) {
      _items.add(CautionBottomSheetItem(
          context: context,
          text: '現在の画像を削除',
          onSelect: () {
            ApplicationRoutes.pop();
            imageFile = null;
            _hasChanged = true;
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
        context: ApplicationRoutes.materialKey.currentContext);
  }

  Future<File> _takePhoto() async {
    final picker = ImagePicker();
    // bool cameraGranted = await Permission.camera.request() == PermissionStatus.granted;
    bool cameraGranted = true;
    if (cameraGranted) {
      final pickedFile = await picker.getImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          this._hasChanged = true;
        });
        return File(pickedFile.path);
      }
    }
    return null;
  }

  Future<File> _selectImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      print('image not selected');
      return null;
    }
  }
}
