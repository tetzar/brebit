import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:brebit/library/image-manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/src/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:uuid/uuid.dart';

import '../../../library/cache.dart';
import '../../../model/draft.dart';
import '../../../model/habit_log.dart';
import '../../../model/image.dart' as ImageModel;
import '../../../model/user.dart';
import '../../../network/post.dart';
import '../../../provider/auth.dart';
import '../../../route/route.dart';
import '../general/loading.dart';
import '../general/multi-image-picker.dart';
import '../widgets/app-bar.dart';
import '../widgets/bottom-sheet.dart';
import '../widgets/dialog.dart';
import 'widget/log-card.dart';

class ThumbSize {
  static const int HEIGHT = 256;
  static const int WIDTH = 256;
  static const int QUALITY = 100;
}

class FormValue {
  String _inputData = '';
  List<AssetEntity> _images = <AssetEntity>[];
  List<File> _imageFiles = <File>[];
  HabitLog _log;

  void setInput(String text) {
    if (text == null) {
      text = '';
    }
    this._inputData = text;
  }

  String getInput() {
    if (this._inputData != null) {
      return this._inputData;
    }
    return '';
  }

  Future<bool> setImage(AssetEntity image) async {
    File imageFile = await getFileFromAssetEntity(image);
    int index = getSameImageIndex(imageFile);
    if (index >= 0) return false;
    _images.add(image);
    _imageFiles.add(imageFile);
    return true;
  }

  Future<bool> setImages(List<AssetEntity> newImages) async {
    this._images = <AssetEntity>[];
    this._imageFiles = <File>[];
    bool added = newImages.isEmpty;
    for (AssetEntity newImage in newImages) {
      if (await this.setImage(newImage)) added = true;
    }
    return added;
  }

  Future<File> getFileFromAssetEntity(AssetEntity image) async {
    File imageFile = await image.file;
    if (!imageFile.isAbsolute) {
      imageFile = imageFile.absolute;
    }
    return imageFile;
  }

  Future<bool> unsetImage(AssetEntity image) async {
    File imageFile = await getFileFromAssetEntity(image);
    int index = getSameImageIndex(imageFile);
    if (index < 0) return false;
    _images.removeAt(index);
    _imageFiles.removeAt(index);
    return true;
  }

  bool sameImage(File imgFile1, File imgFile2) {
    return imgFile1.path == imgFile2.path;
  }

  int getSameImageIndex(File imageFile) {
    for (File file in _imageFiles) {
      if (sameImage(file, imageFile)) return _imageFiles.indexOf(file);
    }
    return -1;
  }

  List<AssetEntity> getImages() {
    return this._images;
  }

  Future<bool> isSetImage(AssetEntity image) async {
    return getSameImageIndex(await getFileFromAssetEntity(image)) >= 0;
  }

  void setLog(HabitLog setLog) {
    this._log = setLog;
  }

  HabitLog getLog() {
    return this._log;
  }

  bool isLogSet() {
    return this._log != null;
  }

  void unsetLog() {
    this._log = null;
  }

  bool savable() {
    return this._inputData.length > 0 ||
        this._images.length > 0 ||
        this._log != null;
  }

  Draft toDraft([Draft draft]) {
    Draft _draft;
    if (draft == null) {
      _draft = Draft();
      _draft.id = Uuid().v1();
    } else {
      _draft = draft;
    }
    _draft.text = this._inputData;
    _draft.imageAssets = this._images;
    _draft.log = this._log;
    return _draft;
  }
}

class CreatePostArguments {
  HabitLog log;
}

FormValue _formValue;

FocusNode _focusNode;

PanelController _panelController;

Future<List<AssetEntity>> _futureFiles;

Future<List<AssetEntity>> _getImages() async {
  bool result = await Permission.storage.isGranted;
  if (result) {
    List<AssetPathEntity> list =
    await PhotoManager.getAssetPathList(type: RequestType.image);
    if (list == null) {
      return <AssetEntity>[];
    }
    if (list.length == 0) {
      return <AssetEntity>[];
    }
    AssetPathEntity allPath =
    list.firstWhere((path) => path.isAll, orElse: null);
    if (allPath == null) {
      list.sort((a, b) => a.assetCount > b.assetCount ? -1 : 1);
      allPath = list.first;
    }
    final assetList = await allPath.getAssetListRange(start: 0, end: 100);
    if (assetList == null) {
      return <AssetEntity>[];
    }
    return assetList;
  } else {
    return null;
  }
}

Future<List<Draft>> _futureDraft;

Future<List<Draft>> _getDrafts(AuthUser user) async {
  List<Draft> drafts = await LocalManager.getDrafts(user);
  return drafts;
}

bool bottomSheetShowing;
//---------------------------------
//  providers
//---------------------------------

final _savableProvider =
StateNotifierProvider.autoDispose((ref) => SavableProvider(false));

class SavableProvider extends StateNotifier<bool> {
  SavableProvider(bool state) : super(state);

  void set(bool s) {
    if (state != s) state = s;
  }
}

final imageSelectProvider = StateNotifierProvider.autoDispose(
        (ref) => ImageSelectProvider(<AssetEntity>[]));

class ImageSelectProvider extends StateNotifier<List<AssetEntity>> {
  ImageSelectProvider(List<AssetEntity> state) : super(state);

  final int maxImages = 4;

  Future<void> set(AssetEntity image) async {
    if ((state.length) < maxImages && await _formValue.setImage(image))
      state = _formValue.getImages();
  }

  Future<void> setAll(List<AssetEntity> images) async {
    if (images.length > maxImages) {
      List<AssetEntity> sub = images.sublist(0, 4);
      if (await _formValue.setImages(sub)) state = sub;
    } else {
      if (await _formValue.setImages(images)) state = images;
    }
  }

  Future<void> unset(AssetEntity image) async {
    if (await _formValue.unsetImage(image)) {
      state = _formValue.getImages();
    }
  }

  Future<int> getIndex(AssetEntity image) async {
    File imageFile = await _formValue.getFileFromAssetEntity(image);
    return _formValue.getSameImageIndex(imageFile);
  }
}

final _draftProvider =
StateNotifierProvider.autoDispose((ref) => DraftProvider(null));

class DraftProvider extends StateNotifier<Draft> {
  DraftProvider(Draft state) : super(state);

  void set(Draft draft) {
    _formValue.setInput(draft.text);
    _formValue.setLog(draft.log);
    this.state = draft;
  }
}

enum InputState { text, image, disabled }

final _inputScopeProvider = StateNotifierProvider.autoDispose(
        (ref) => InputScopeProvider(InputState.text));

class InputScopeProvider extends StateNotifier<InputState> {
  InputScopeProvider(InputState state) : super(state);

  void set(InputState s) {
    if (s == InputState.text) {
      _panelController.animatePanelToPosition(0, duration: Duration.zero);
      if (state != InputState.text) {
        _focusNode.requestFocus();
      }
    } else if (s == InputState.image) {
      _focusNode.unfocus();
      Timer(Duration(milliseconds: 200), () {
        _panelController.open();
      });
    } else {
      _focusNode.unfocus();
      _panelController.animatePanelToPosition(0);
    }
    if (s != state) {
      state = s;
    }
  }

  InputState getState() {
    return this.state;
  }

  bool isText() {
    return state == InputState.text;
  }

  bool isImage() {
    return state == InputState.image;
  }

  bool isDisabled() {
    return state == InputState.disabled;
  }
}

final _showLibraryButtonProvider = StateNotifierProvider.autoDispose(
        (ref) => ShowLibraryButtonProvider(false));

class ShowLibraryButtonProvider extends StateNotifier<bool> {
  ShowLibraryButtonProvider(bool state) : super(state);

  void show() {
    if (!state) {
      state = true;
    }
  }

  void hide() {
    if (state) {
      state = false;
    }
  }
}

//---------------------------------
//  build
//---------------------------------

class CreatePost extends StatelessWidget {
  final CreatePostArguments args;

  CreatePost({@required this.args});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await onBack(context);
        return false;
      },
      child: Scaffold(
        appBar: getMyAppBar(
            context: context,
            titleText: '',
            actions: [
              InkWell(
                  onTap: () async {
                    context.read(_inputScopeProvider).set(InputState.disabled);
                    Draft draft = await ApplicationRoutes.push(
                        MaterialPageRoute(
                            builder: (BuildContext context) => DraftScreen()));
                    if (draft != null) {
                      context.read(_draftProvider).set(draft);
                      context
                          .read(imageSelectProvider)
                          .setAll(draft.imageAssets);
                      context.read(_savableProvider).set(_formValue.savable());
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 16),
                    alignment: Alignment.center,
                    child: Text(
                      '下書き',
                      style: TextStyle(
                          color: Theme
                              .of(context)
                              .accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  )),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () async {
                      await save();
                    },
                    child: HookBuilder(
                      builder: (BuildContext context) {
                        bool savable = useProvider(_savableProvider.state);
                        return Container(
                          margin: EdgeInsets.only(right: 16),
                          width: 84,
                          height: 34,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(17),
                              color: savable
                                  ? Theme
                                  .of(context)
                                  .accentColor
                                  : Theme
                                  .of(context)
                                  .accentColor
                                  .withOpacity(0.4)),
                          alignment: Alignment.center,
                          child: Text(
                            'ポスト',
                            style: TextStyle(
                                color: Theme
                                    .of(context)
                                    .primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
            onBack: () async {
              await onBack(context);
            },
            background: AppBarBackground.white),
        body: Container(
          child: InputForm(
            args: args,
          ),
        ),
        // body: TextFormField(
        //   focusNode: _focusNode,
        // ),
      ),
    );
  }

  Future<void> save() async {
    if (_formValue.savable()) {
      _focusNode.unfocus();
      try {
        MyLoading.startLoading();
        List<File> files = [];
        for (AssetEntity asset in _formValue.getImages()) {
          File file = await asset.file;
          file = await ImageModel.Image.resizeImage(file);
          files.add(file);
        }
        await PostApi.savePost(
            _formValue.getInput(), files, _formValue.getLog());
        await MyLoading.dismiss();
        ApplicationRoutes.pop('reload');
      } catch (e) {
        await MyLoading.dismiss();
        MyErrorDialog.show(e);
      }
    }
  }

  Future<void> onBack(BuildContext context) async {
    if (!_formValue.savable()) {
      _focusNode.unfocus();
      ApplicationRoutes.pop();
      return;
    }
    context.read(_inputScopeProvider).set(InputState.disabled);
    Timer(Duration(milliseconds: 300), () {
      if (bottomSheetShowing) {
        return;
      }
      bottomSheetShowing = true;
      showCustomBottomSheet(
          items: <BottomSheetItem>[
            BottomSheetItem(
                onTap: () {
                  if (context.read(_draftProvider.state) != null) {
                    LocalManager.removeDraft(
                        context
                            .read(authProvider.state)
                            .user,
                        context.read(_draftProvider.state));
                  }
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  '投稿を破棄',
                  style: Theme
                      .of(context)
                      .accentTextTheme
                      .subtitle1
                      .copyWith(fontSize: 18),
                )),
            BottomSheetItem(
                onTap: () {
                  LocalManager.setDraft(context
                      .read(authProvider.state)
                      .user,
                      _formValue.toDraft(context.read(_draftProvider.state)));
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  '下書きに保存',
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 18),
                )),
            BottomSheetItem(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'キャンセル',
                  style: TextStyle(
                      color: Theme
                          .of(context)
                          .disabledColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ))
          ],
          backGroundColor: Theme
              .of(context)
              .primaryColor,
          context: context,
          onClosed: () {
            bottomSheetShowing = false;
          });
    });
  }
}

class InputForm extends StatefulHookWidget {
  final CreatePostArguments args;

  InputForm({@required this.args});

  @override
  _InputFormState createState() => _InputFormState();
}

class _InputFormState extends State<InputForm> {
  bool keyboardVisible;
  TextEditingController _controller;
  ImageChangedNotifier imageChangedNotifier;

  @override
  void initState() {
    super.initState();
    bottomSheetShowing = false;
    _futureFiles = _getImages();
    _formValue = new FormValue();
    if (widget.args != null) {
      if (widget.args.log != null) {
        _formValue.setLog(widget.args.log);
      }
    }
    context.read(_showLibraryButtonProvider).hide();
    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardVisibilityController.onChange.listen((bool visible) {
      if (!visible) {
        _focusNode.unfocus();
      }
    });
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        context.read(_inputScopeProvider).set(InputState.text);
      } else {
        if (!context.read(_inputScopeProvider).isImage()) {
          context.read(_inputScopeProvider).set(InputState.disabled);
        }
      }
    });
    _futureDraft = _getDrafts(context
        .read(authProvider.state)
        .user);
    _controller = TextEditingController();
    _panelController = new PanelController();
    context.read(_savableProvider).set(_formValue.savable());
    imageChangedNotifier = new ImageChangedNotifier();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    useProvider(_draftProvider.state);
    List<Widget> _formWidgets = <Widget>[];
    String text = _formValue.getInput();
    _controller.text = text;
    _formWidgets.add(TextFormField(
      // controller: _controller,
      onChanged: (String value) {
        _formValue.setInput(value);
        context.read(_savableProvider).set(_formValue.savable());
      },
      style: Theme
          .of(context)
          .textTheme
          .bodyText1
          .copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 15,
      ),
      autofocus: true,
      focusNode: _focusNode,
      maxLines: null,
      textAlign: TextAlign.left,
      decoration: InputDecoration(
          contentPadding: EdgeInsets.all(0),
          fillColor: Colors.transparent,
          hintText: '日記・ひとことメモ',
          hintStyle:
          Theme
              .of(context)
              .textTheme
              .subtitle1
              .copyWith(fontSize: 15)),
    ));
    HabitLog log = _formValue.getLog();
    if (log != null) {
      _formWidgets.add(LogCard(
        log: log,
      ));
    }
    _formWidgets.add(SelectedImages(changeNotifier: imageChangedNotifier));
    _formWidgets.add(HookBuilder(
      builder: (BuildContext context) {
        InputState _inputState = useProvider(_inputScopeProvider.state);
        return SizedBox(
          width: double.infinity,
          height: _inputState == InputState.image ? 310 : 50,
        );
      },
    ));

    List<Widget> widgets = <Widget>[];
    widgets.add(InputSwitcher(switcherHeight: 44));
    widgets.add(ImagePick(
      changeNotifier: imageChangedNotifier,
    ));

    return Stack(
      children: [
        Container(
          color: Theme
              .of(context)
              .primaryColor,
          height: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _formWidgets),
          ),
        ),
        SlidingUpPanel(
            minHeight: 44,
            boxShadow: [BoxShadow(color: Colors.transparent)],
            maxHeight: 304,
            color: Theme
                .of(context)
                .primaryColor,
            isDraggable: false,
            controller: _panelController,
            defaultPanelState: PanelState.CLOSED,
            onPanelOpened: () {
              context.read(_showLibraryButtonProvider).show();
            },
            onPanelClosed: () {
              context.read(_showLibraryButtonProvider).hide();
            },
            panel: Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width,
                child: Column(
                  children: widgets,
                ))),
        Positioned(
          left: 16,
          bottom: 16,
          child: HookBuilder(
            builder: (BuildContext context) {
              bool _show = useProvider(_showLibraryButtonProvider.state);
              if (_show) {
                return InkWell(
                  onTap: () async {
                    await pickImage(context);
                  },
                  child: Container(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 34,
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(17),
                              color: Theme
                                  .of(context)
                                  .primaryColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme
                                      .of(context)
                                      .shadowColor,
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: Offset(0, 0),
                                )
                              ]),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.only(
                                  right: 9,
                                ),
                                child: Icon(
                                  Icons.photo_library_rounded,
                                  size: 12,
                                  color: Theme
                                      .of(context)
                                      .accentColor,
                                ),
                              ),
                              Text(
                                'ライブラリ',
                                style: TextStyle(
                                    color: Theme
                                        .of(context)
                                        .accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              } else {
                return Container(
                  height: 0,
                  width: 0,
                );
              }
            },
          ),
        )
      ],
    );
  }

  Future<void> pickImage(BuildContext context) async {
    try {
      List<AssetEntity> assets = await MyMultiImagePicker.pickImages(
          max: 4, selected: context.read(imageSelectProvider.state).toList(growable: true));
      if (assets == null) return;
      List<File> currentSelected = await ImageManager.assetEntitiesToFiles(context.read(
          imageSelectProvider.state).toList(growable: false));
      await context.read(imageSelectProvider).setAll(assets);
      imageChangedNotifier.notify(
        currentSelected.map((f) => f.path).toList(growable: false)
      );
      await imageChangedNotifier.notifyToSelected(context);
    } on Exception catch (e) {
      throw e;
    }
  }
}

class InputSwitcher extends StatefulHookWidget {
  final double switcherHeight;

  InputSwitcher({@required this.switcherHeight});

  @override
  _InputSwitcherState createState() => _InputSwitcherState();
}

class _InputSwitcherState extends State<InputSwitcher> {
  @override
  Widget build(BuildContext context) {
    useProvider(_inputScopeProvider.state);
    return Container(
      margin: EdgeInsets.only(left: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          getButton(
              icon: Icons.keyboard,
              selected: context.read(_inputScopeProvider).isText(),
              context: context,
              onTap: () {
                if (!context.read(_inputScopeProvider).isText()) {
                  showKeyboard(context);
                }
              },
              iconSize: 24),
          getButton(
              icon: Icons.image,
              selected: context.read(_inputScopeProvider).isImage(),
              context: context,
              onTap: () {
                if (!context.read(_inputScopeProvider).isImage()) {
                  showImagePicker(context);
                }
              },
              iconSize: 22)
        ],
      ),
    );
  }

  Widget getButton({@required IconData icon,
    @required bool selected,
    @required BuildContext context,
    @required Function onTap,
    @required double iconSize}) {
    Color color = selected
        ? Theme
        .of(context)
        .accentColor
        : Theme
        .of(context)
        .disabledColor;
    return InkWell(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 10),
          width: 24,
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              Container(
                height: 24,
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: iconSize,
                  color: color,
                ),
              ),
              Container(
                  height: 10,
                  width: double.infinity,
                  child: Container(
                    padding: EdgeInsets.only(top: 1),
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? color : Colors.transparent),
                    ),
                  ))
            ],
          ),
        ));
  }

  void showImagePicker(BuildContext context) {
    context.read(_inputScopeProvider).set(InputState.image);
  }

  void showKeyboard(BuildContext context) {
    context.read(_inputScopeProvider).set(InputState.text);
  }
}

class ImageChangedNotifier {
  Map<String, VoidCallback> listeners = {};

  void addListener(VoidCallback callback, String path) {
    listeners[path] = callback;
  }

  void notify(List<String> paths) {
    for (String path in paths) {
      VoidCallback callback = listeners[path];
      if (callback != null) callback();
    }
  }

  Future<void> notifyToSelected(BuildContext context) async {
    await notifyChangeToCardWithAssets(context.read(imageSelectProvider.state));
  }

  Future<void> notifyChangeToCardWithAssets(List<AssetEntity> assets) async {
    notify((await ImageManager.assetEntitiesToFiles(assets.toList(growable: false)))
        .map((f) => f.path).toList(growable: false));
  }
}

class SelectedImages extends HookWidget {
  final ImageChangedNotifier changeNotifier;

  SelectedImages({@required this.changeNotifier});

  @override
  Widget build(BuildContext context) {
    List<AssetEntity> imageAssets = useProvider(imageSelectProvider.state);
    List<ImageCard> images = <ImageCard>[];
    int i = 0;
    imageAssets.forEach((asset) {
      images.add(ImageCard(
        imageAsset: asset,
        isFirst: i == 0,
        changeNotifier: changeNotifier,
      ));
      i++;
    });
    return Container(
      margin: EdgeInsets.only(top: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: images,
        ),
      ),
    );
  }
}

class ImageCard extends StatefulWidget {
  final AssetEntity imageAsset;
  final bool isFirst;
  final ImageChangedNotifier changeNotifier;

  ImageCard({@required this.imageAsset,
    @required this.isFirst,
    @required this.changeNotifier});

  @override
  _ImageCardState createState() => _ImageCardState();
}

class _ImageCardState extends State<ImageCard> {
  Uint8List _image;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.imageAsset
          .thumbDataWithSize(ThumbSize.WIDTH, ThumbSize.HEIGHT,
          quality: ThumbSize.QUALITY)
          .then((Uint8List _data) {
        setState(() {
          _image = _data;
        });
      });
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ImageCard oldWidget) {
    widget.imageAsset
        .thumbDataWithSize(ThumbSize.WIDTH, ThumbSize.HEIGHT,
        quality: ThumbSize.QUALITY)
        .then((Uint8List _data) {
      setState(() {
        _image = _data;
      });
    });
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_image == null) {
      child = Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme
            .of(context)
            .disabledColor,
      );
    } else {
      child = Container(
        width: double.infinity,
        height: double.infinity,
        child: Image.memory(
          _image,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme
              .of(context)
              .disabledColor),
      width: 100,
      height: 100,
      margin: EdgeInsets.only(left: widget.isFirst ? 0 : 8),
      child: Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
          Positioned(
            right: 6,
            top: 6,
            child: InkWell(
                onTap: () {
                  removeImage(context);
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme
                          .of(context)
                          .primaryColor),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.clear,
                    size: 12,
                  ),
                )),
          )
        ],
      ),
    );
  }

  void removeImage(BuildContext context) {
    context.read(imageSelectProvider).unset(widget.imageAsset);
    context.read(_savableProvider).set(_formValue.savable());
    widget.changeNotifier.notifyToSelected(context);
  }
}

class ImagePick extends StatefulWidget {
  final ImageChangedNotifier changeNotifier;

  ImagePick({@required this.changeNotifier});

  @override
  _ImagePickState createState() => _ImagePickState();
}

class _ImagePickState extends State<ImagePick>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 260,
      child: FutureBuilder(
        future: _futureFiles,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Container(
              width: 0,
              height: 0,
            );
          } else {
            if (snapshot.data == null) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 24),
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'ポストに写真を追加するには、Brebitによる写真へのアクセスを許可してください。',
                      style: Theme
                          .of(context)
                          .textTheme
                          .subtitle1
                          .copyWith(fontSize: 12, fontWeight: FontWeight.w400),
                    ),
                    SizedBox(
                      height: 32,
                    ),
                    GestureDetector(
                      child: Text(
                        '写真へのアクセスを許可',
                        style: TextStyle(
                            color: Theme
                                .of(context)
                                .accentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ),
                      onTap: () {
                        requestLibraryPermission();
                      },
                    )
                  ],
                ),
              );
            } else {
              List<AssetEntity> imageFiles = snapshot.data;
              List<Widget> cards = <Widget>[];
              imageFiles.forEach((imageFile) {
                cards.add(ImageTile(
                  imageAsset: imageFile,
                  changeNotifier: widget.changeNotifier,
                ));
              });
              return GridView.count(
                crossAxisCount: 2,
                scrollDirection: Axis.horizontal,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                cacheExtent: 1000,
                children: cards,
              );
            }
          }
        },
      ),
    );
  }

  Future<void> requestLibraryPermission() async {
    if (await Permission.storage
        .request()
        .isGranted) {
      setState(() {
        _futureFiles = _getImages();
      });
    } else {
      print('deny');
    }
  }
}

class ImageTile extends StatefulWidget {
  final AssetEntity imageAsset;
  final ImageChangedNotifier changeNotifier;

  ImageTile({
    @required this.imageAsset,
    @required this.changeNotifier,
  });

  @override
  _ImageTileState createState() => _ImageTileState();
}

class _ImageTileState extends State<ImageTile> {
  Uint8List image;
  int index = -1;
  VoidCallback changeIndexListener;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.imageAsset
          .thumbDataWithSize(ThumbSize.WIDTH, ThumbSize.HEIGHT,
          quality: ThumbSize.QUALITY)
          .then((Uint8List data) {
        if (mounted) {
          setState(() {
            image = data;
          });
        }
      });
    });
    changeIndexListener = () {
      getIndex(context);
    };
    ImageManager.assetEntityToFile(widget.imageAsset).then((file) {
      widget.changeNotifier.addListener(changeIndexListener, file.path);
    });
    getIndex(context);
    super.initState();
  }

  void getIndex(BuildContext context) {
    context.read(imageSelectProvider).getIndex(widget.imageAsset).then((i) {
      this.setIndex(i);
    });
  }

  void setIndex(int i) {
    if (this.index != i)
      setState(() {
        this.index = i;
      });
  }

  @override
  Widget build(BuildContext context) {
    bool isSelected = index >= 0;
    Widget child;
    if (image == null) {
      child = Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme
            .of(context)
            .disabledColor,
      );
    } else {
      child = Container(
        width: double.infinity,
        height: double.infinity,
        child: Image.memory(
          image,
          color: Colors.white.withOpacity(isSelected ? 0.3 : 1),
          colorBlendMode: BlendMode.modulate,
          fit: BoxFit.cover,
        ),
      );
    }
    return InkWell(
        onTap: () async {
          if (isSelected) {
            await context.read(imageSelectProvider).unset(widget.imageAsset);
          } else {
            await context.read(imageSelectProvider).set(widget.imageAsset);
          }
          context.read(_savableProvider).set(_formValue.savable());
          await widget.changeNotifier.notifyToSelected(context);
          getIndex(context);
        },
        child: Container(
          width: 129,
          height: 129,
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(child: child, opacity: animation);
                },
                child: child,
              ),
              isSelected
                  ? Positioned(
                  right: 4,
                  top: 4,
                  height: 20,
                  width: 20,
                  child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme
                            .of(context)
                            .primaryColor),
                    alignment: Alignment.center,
                    child: Text(
                      (index + 1).toString(),
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 10),
                    ),
                  ))
                  : Container(
                width: 0,
                height: 0,
              )
            ],
          ),
        ));
  }
}

class DraftScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(
        background: AppBarBackground.white,
        backButton: AppBarBackButton.x,
        onBack: () {
          Navigator.pop(context);
        },
        context: context,
      ),
      body: DraftList(),
    );
  }
}

class DraftList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: MediaQuery
          .of(context)
          .size
          .width,
      color: Theme
          .of(context)
          .primaryColor,
      child: FutureBuilder(
        future: _futureDraft,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else {
            List<Widget> columnChildren = <Widget>[];
            for (Draft draft in snapshot.data) {
              columnChildren.add(DraftTile(draft: draft));
            }
            return SingleChildScrollView(
              child: Column(
                children: columnChildren,
              ),
            );
          }
        },
      ),
    );
  }
}

class DraftTile extends StatefulWidget {
  final Draft draft;

  DraftTile({@required this.draft});

  @override
  _DraftTileState createState() => _DraftTileState();
}

class _DraftTileState extends State<DraftTile> {
  List<Uint8List> _imageData;

  @override
  void initState() {
    getImageData().then((list) {
      setState(() {
        _imageData = list;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rowChildren = <Widget>[];
    List<Widget> columnChildren = <Widget>[];
    rowChildren.add(Expanded(
      child: Text(widget.draft.text ?? '',
          style: Theme
              .of(context)
              .textTheme
              .bodyText1
              .copyWith(fontSize: 15)),
    ));
    if (widget.draft.imageAssets != null) {
      if (widget.draft.imageAssets.length > 0) {
        Duration duration = Duration(milliseconds: 200);
        Widget images;
        switch (widget.draft.imageAssets.length) {
          case 1:
            images = AnimatedContainer(
              duration: duration,
              margin: EdgeInsets.only(left: 8),
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                  color: Theme
                      .of(context)
                      .disabledColor,
                  borderRadius: BorderRadius.circular(8),
                  image: _imageData == null
                      ? null
                      : DecorationImage(
                      image: MemoryImage(_imageData[0]),
                      fit: BoxFit.cover)),
            );
            break;
          case 2:
            images = Container(
              margin: EdgeInsets.only(left: 8),
              height: 60,
              width: 60,
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: duration,
                      margin: EdgeInsets.only(right: 0.5),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8)),
                          image: _imageData == null
                              ? null
                              : DecorationImage(
                              image: MemoryImage(_imageData[0]),
                              fit: BoxFit.cover)),
                    ),
                  ),
                  Expanded(
                      child: AnimatedContainer(
                        duration: duration,
                        margin: EdgeInsets.only(left: 0.5),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8)),
                            image: _imageData == null
                                ? null
                                : DecorationImage(
                                image: MemoryImage(_imageData[1]),
                                fit: BoxFit.cover)),
                      ))
                ],
              ),
            );
            break;
          case 3:
            images = Container(
              margin: EdgeInsets.only(left: 8),
              height: 60,
              width: 60,
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: duration,
                      margin: EdgeInsets.only(right: 0.5),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8)),
                          image: _imageData == null
                              ? null
                              : DecorationImage(
                              image: MemoryImage(_imageData[0]),
                              fit: BoxFit.cover)),
                    ),
                  ),
                  Expanded(
                      child: Container(
                        margin: EdgeInsets.only(left: 0.5),
                        child: Column(
                          children: [
                            Expanded(
                              child: AnimatedContainer(
                                duration: duration,
                                margin: EdgeInsets.only(bottom: 0.5),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(8)),
                                    image: _imageData == null
                                        ? null
                                        : DecorationImage(
                                        image: MemoryImage(_imageData[1]),
                                        fit: BoxFit.cover)),
                              ),
                            ),
                            Expanded(
                              child: AnimatedContainer(
                                duration: duration,
                                margin: EdgeInsets.only(top: 0.5),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        bottomRight: Radius.circular(8)),
                                    image: _imageData == null
                                        ? null
                                        : DecorationImage(
                                        image: MemoryImage(_imageData[2]),
                                        fit: BoxFit.cover)),
                              ),
                            ),
                          ],
                        ),
                      ))
                ],
              ),
            );
            break;
          default:
            images = Container(
              margin: EdgeInsets.only(left: 8),
              height: 60,
              width: 60,
              child: Row(
                children: [
                  Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: 0.5),
                        child: Column(
                          children: [
                            Expanded(
                              child: AnimatedContainer(
                                duration: duration,
                                margin: EdgeInsets.only(bottom: 0.5),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8)),
                                    image: _imageData == null
                                        ? null
                                        : DecorationImage(
                                        image: MemoryImage(_imageData[0]),
                                        fit: BoxFit.cover)),
                              ),
                            ),
                            Expanded(
                              child: AnimatedContainer(
                                duration: duration,
                                margin: EdgeInsets.only(top: 0.5),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(8)),
                                    image: _imageData == null
                                        ? null
                                        : DecorationImage(
                                        image: MemoryImage(_imageData[1]),
                                        fit: BoxFit.cover)),
                              ),
                            ),
                          ],
                        ),
                      )),
                  Expanded(
                      child: Container(
                        margin: EdgeInsets.only(left: 0.5),
                        child: Column(
                          children: [
                            Expanded(
                              child: AnimatedContainer(
                                duration: duration,
                                margin: EdgeInsets.only(bottom: 0.5),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(8)),
                                    image: _imageData == null
                                        ? null
                                        : DecorationImage(
                                        image: MemoryImage(_imageData[2]),
                                        fit: BoxFit.cover)),
                              ),
                            ),
                            Expanded(
                              child: AnimatedContainer(
                                duration: duration,
                                margin: EdgeInsets.only(top: 0.5),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        bottomRight: Radius.circular(8)),
                                    image: _imageData == null
                                        ? null
                                        : DecorationImage(
                                        image: MemoryImage(_imageData[3]),
                                        fit: BoxFit.cover)),
                              ),
                            ),
                          ],
                        ),
                      ))
                ],
              ),
            );
            break;
        }
        rowChildren.add(images);
      }
    }
    columnChildren.add(Row(
      children: rowChildren,
    ));
    if (widget.draft.log != null) {
      columnChildren.add(SizedBox(
        height: 8,
      ));
      columnChildren.add(LogCard(log: widget.draft.log));
    }
    return InkWell(
        onTap: () {
          ApplicationRoutes.pop(widget.draft);
        },
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(children: columnChildren),
        ));
  }

  Future<List<Uint8List>> getImageData() async {
    List<AssetEntity> assets = widget.draft.imageAssets;
    List<Uint8List> data = <Uint8List>[];
    for (AssetEntity asset in assets) {
      Uint8List d = await asset.thumbDataWithSize(
          ThumbSize.WIDTH, ThumbSize.HEIGHT,
          quality: ThumbSize.QUALITY);
      data.add(d);
    }
    return data;
  }
}