import 'dart:io';

import 'package:brebit/view/general/error-widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../model/image.dart' as ImageModel;
import '../../../../model/user.dart';
import '../../../../provider/auth.dart';
import '../../../../route/route.dart';
import '../../general/image-crop.dart';
import '../../general/loading.dart';
import '../../home/navigation.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/bottom-sheet.dart';
import '../../widgets/dialog.dart';
import '../../widgets/text-field.dart';

class ProfileSettingProviderState {
  String? nickName;
  File? imageFile;
  String? bio;
  Widget? image;
}

class ProfileSettingProvider
    extends StateNotifier<ProfileSettingProviderState> {
  ProfileSettingProvider(ProfileSettingProviderState state) : super(state);

  void set({String? nickName, String? bio, File? imageFile, Widget? image}) {
    this.state.nickName = nickName ?? this.state.nickName;
    this.state.bio = bio ?? this.state.bio;
    this.state.imageFile = imageFile ?? this.state.imageFile;
    this.state.image = image ?? this.state.image;
  }

  void setImageFile(File? file) {
    this.state.imageFile = file;
    state = state;
  }

  bool savable(AuthUser user) {
    if (user.getImageUrl().length > 0 && this.state.image == null) {
      return true;
    }
    if (this.name.length == 0) {
      return false;
    }
    return this.state.imageFile != null ||
        this.state.nickName != user.name ||
        this.state.bio != user.bio;
  }

  File? get file {
    return this.state.imageFile;
  }

  String get name {
    return this.state.nickName ?? '';
  }

  String get bio {
    return this.state.bio ?? '';
  }

  set bio(String bio) {
    this.state.bio = bio;
  }

  set file(File? file) {
    this.state.imageFile = file;
  }

  set name(String name) {
    this.state.nickName = name;
  }

  void setName(String name, AuthUser user) {
    bool notify = false;
    if (this.name == user.name) {
      if (name != user.name) {
        notify = true;
      }
    } else {
      if (name == user.name) {
        notify = true;
      }
    }
    if ((name.length == 0 && this.name.length > 0) ||
        (this.name.length == 0 && name.length > 0)) notify = true;
    this.name = name;
    if (notify) state = state;
  }

  void setBio(String text, AuthUser user) {
    bool notify = (user.bio == text) != (this.bio == user.bio);
    this.bio = text;
    if (notify) state = state;
  }

  set image(Widget? imageWidget) {
    if (imageWidget == null) {
      this.file = null;
    }
    this.state.image = imageWidget;
  }

  Widget? get image {
    File? imageFile = this.state.imageFile;
    if (imageFile != null) {
      return Image.file(imageFile);
    }
    return this.state.image ??
        Image.asset(
          'assets/icon/default.png',
          fit: BoxFit.cover,
        );
  }

  bool imageDeletable() {
    return this.file != null || this.state.image != null;
  }

  void setImage(Widget? imageWidget) {
    this.image = imageWidget;
    state = state;
  }
}

final _profileSettingProvider = StateNotifierProvider.autoDispose(
    (ref) => ProfileSettingProvider(ProfileSettingProviderState()));

class ProfileSetting extends ConsumerStatefulWidget {
  @override
  _ProfileSettingState createState() => _ProfileSettingState();
}

class _ProfileSettingState extends ConsumerState<ProfileSetting> {
  late AuthUser? user;

  @override
  void initState() {
    AuthUser? user = ref.read(authProvider.notifier).user;
    this.user = user;
    if (user != null) {
      String currentImageUrl = user.getImageUrl();
      ref.read(_profileSettingProvider.notifier).set(
          nickName: user.name,
          bio: user.bio,
          image: currentImageUrl.length > 0 ? user.getImageWidget() : null);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AuthUser? user = this.user;
    if (user == null) return ErrorToHomeWidget();
    return WillPopScope(
      onWillPop: () {
        return onWillPop(context, ref);
      },
      child: Scaffold(
          appBar: getMyAppBar(
              context: context,
              titleText: 'プロフィール',
              actions: [
                SaveButton(
                  user: user,
                )
              ],
              onBack: () async {
                await onWillPop(context, ref);
              }),
          body: ProfileForm(
            user: user,
          )),
    );
  }

  Future<bool> onWillPop(BuildContext ctx, WidgetRef ref) async {
    AuthUser? user = ref.read(authProvider.notifier).user;
    if (user != null &&
        ref.read(_profileSettingProvider.notifier).savable(user)) {
      showCancelDialog(ctx);
    } else {
      Home.pop();
    }
    return false;
  }

  void showCancelDialog(BuildContext ctx) {
    showDialog(
        context: ctx,
        builder: (context) {
          return MyDialog(
              title: Text(
                '変更を破棄してもよろしいですか？',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyText1?.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 18),
              ),
              body: SizedBox(
                height: 0,
              ),
              actionText: '破棄する',
              actionColor: Theme.of(context).primaryTextTheme.subtitle1?.color,
              action: () {
                Navigator.pop(context);
                Home.pop();
              });
        });
  }
}

class SaveButton extends ConsumerWidget {
  final AuthUser user;

  SaveButton({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(_profileSettingProvider);
    bool savable = ref.read(_profileSettingProvider.notifier).savable(user);
    return IconButton(
      icon: Icon(Icons.check,
          color: savable
              ? Theme.of(context).appBarTheme.iconTheme?.color
              : Theme.of(context).disabledColor),
      onPressed: savable
          ? () {
              save(context, ref);
            }
          : null,
    );
  }

  Future<void> save(BuildContext ctx, WidgetRef ref) async {
    File? imageFile = ref.read(_profileSettingProvider.notifier).file;
    if (imageFile != null) {
      imageFile = await ImageModel.Image.resizeImage(imageFile);
    }
    String nickName = ref.read(_profileSettingProvider.notifier).name;
    if (nickName.length == 0) {
      return;
    }
    String bio = ref.read(_profileSettingProvider.notifier).bio;
    bool imageDeleted = this.user.hasImage() &&
        ref.read(_profileSettingProvider.notifier).image == null;
    try {
      MyLoading.startLoading();
      await ref
          .read(authProvider.notifier)
          .saveProfile(nickName, bio, imageFile, imageDeleted);
      await MyLoading.dismiss();
      Navigator.pop(ctx);
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }
}

class ProfileForm extends ConsumerWidget {
  final AuthUser user;

  ProfileForm({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: double.infinity,
      color: Theme.of(context).primaryColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfileImage(),
              SizedBox(
                height: 16,
              ),
              NameForm(
                user: user,
              ),
              SizedBox(
                height: 16,
              ),
              BioForm(
                user: user,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileImage extends ConsumerStatefulWidget {
  @override
  _ProfileImageState createState() => _ProfileImageState();
}

class _ProfileImageState extends ConsumerState<ProfileImage> {
  @override
  Widget build(BuildContext context) {
    Widget? imageWidget = ref.read(_profileSettingProvider.notifier).image;
    return Container(
      width: 80,
      height: 80,
      child: InkWell(
        onTap: () {
          showOptions(context);
        },
        child: Stack(
          children: [
            CircleAvatar(
              child: ClipOval(child: imageWidget),
              radius: 40,
              // backgroundImage: NetworkImage('https://via.placeholder.com/300'),
              backgroundColor: Colors.transparent,
            ),
            Positioned(
              bottom: 1,
              right: 3,
              child: Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context)
                      .textTheme
                      .bodyText1
                      ?.color
                      ?.withOpacity(0.5),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/icon/camera.svg',
                  color: Theme.of(context).primaryColor,
                  height: 12,
                  width: 12,
                ),
              ),
            )
          ],
        ),
      ),
    );
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
              ref
                  .read(_profileSettingProvider.notifier)
                  .setImageFile(await MyImageCropper.cropImage(context, file));
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
            ref
                .read(_profileSettingProvider.notifier)
                .setImageFile(await MyImageCropper.cropImage(context, file));
            setState(() {});
          }
        },
      )
    ];
    if (ref.read(_profileSettingProvider.notifier).imageDeletable()) {
      _items.add(CautionBottomSheetItem(
          context: context,
          text: '現在の画像を削除',
          onSelect: () {
            ApplicationRoutes.pop();
            ref.read(_profileSettingProvider.notifier).setImage(null);
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

  Future<File?> _takePhoto() async {
    final picker = ImagePicker();
    bool cameraGranted =
        await Permission.camera.request() == PermissionStatus.granted;
    if (cameraGranted) {
      XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    }
    return null;
  }

  Future<File?> _selectImageFromGallery() async {
    if (!await Permission.storage.isGranted) {
      await Permission.storage.request();
      if (await Permission.storage.isDenied) {
        return null;
      }
    }
    final picker = ImagePicker();
    XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      print('image not selected');
      return null;
    }
  }
}

class NameForm extends ConsumerWidget {
  final AuthUser user;

  NameForm({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      child: MyTextField(
        validate: (String? text) {
          if (text == null || text.length == 0) {
            return 'ニックネームを入力してください';
          }
          return null;
        },
        onChanged: (String text) {
          ref.read(_profileSettingProvider.notifier).setName(text, user);
        },
        hintText: 'やまだたろう',
        label: 'ニックネーム',
        initialValue: ref.read(_profileSettingProvider.notifier).name,
        autoValidateMode: AutovalidateMode.always,
      ),
    );
  }
}

class BioForm extends ConsumerWidget {
  final AuthUser user;

  BioForm({required this.user});

  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      child: MyTextField(
        validate: (_) {
          return null;
        },
        label: 'ステータスメッセージ',
        maxLines: 5,
        initialValue: ref.read(_profileSettingProvider.notifier).bio,
        hintText: 'プロフィールや意気込みを教えて下さい',
        onChanged: (String text) {
          ref.read(_profileSettingProvider.notifier).setBio(text, user);
        },
      ),
    );
  }
}
