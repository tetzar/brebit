import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

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
import 'widget/log-card.dart';
import '../widgets/app-bar.dart';
import '../widgets/bottom-sheet.dart';
import '../widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:uuid/uuid.dart';

class FormValue {
  String _inputData = '';
  List<AssetEntity> _images = <AssetEntity>[];
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

  void setImage(AssetEntity image) {
    int index = _images.indexWhere((img) => sameImage(image, img));
    if (index < 0) {
      _images.add(image);
    }
  }

  void setImages(List<AssetEntity> newImages) {
    this._images = <AssetEntity>[];
    newImages.forEach((newImage) {
      this.setImage(newImage);
    });
  }

  void unsetImage(AssetEntity image) {
    _images.removeWhere((img) => sameImage(image, img));
  }

  bool sameImage(AssetEntity image1, AssetEntity image2) {
    return image1.relativePath + image1.title ==
        image2.relativePath + image2.title;
  }

  List<AssetEntity> getImages() {
    return this._images;
  }

  bool isSetImage(AssetEntity image) {
    int index = _images.indexWhere((img) => sameImage(image, img));
    return index >= 0;
  }

  void removeImage(AssetEntity image) {
    _images.removeWhere((img) => sameImage(image, img));
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
    final assetList = await list.first.getAssetListRange(start: 0, end: 100);
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
    if (state != s) {
      state = s;
    }
  }
}

final imageSelectProvider = StateNotifierProvider.autoDispose(
    (ref) => ImageSelectProvider(<AssetEntity>[]));

class ImageSelectProvider extends StateNotifier<List<AssetEntity>> {
  ImageSelectProvider(List<AssetEntity> state) : super(state);

  final int maxImages = 4;

  void set(AssetEntity image) async {
    if ((state.length) < maxImages) {
      _formValue.setImage(image);
      state = _formValue.getImages();
    }
  }

  void setAll(List<AssetEntity> images) async {
    if (images.length > maxImages) {
      List<AssetEntity> sub = images.sublist(0, 4);
      _formValue.setImages(sub);
      state = sub;
    } else {
      _formValue.setImages(images);
      state = images;
    }
  }

  void unset(AssetEntity image) {
    _formValue.unsetImage(image);
    state = _formValue.getImages();
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
                          color: Theme.of(context).accentColor,
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
                                  ? Theme.of(context).accentColor
                                  : Theme.of(context)
                                      .accentColor
                                      .withOpacity(0.4)),
                          alignment: Alignment.center,
                          child: Text(
                            'ポスト',
                            style: TextStyle(
                                color: Theme.of(context).primaryColor,
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
        body: InputForm(
          args: args,
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
        await PostApi.savePost(_formValue.getInput(), files, _formValue.getLog());
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
                        context.read(authProvider.state).user,
                        context.read(_draftProvider.state));
                  }
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  '投稿を破棄',
                  style: Theme.of(context)
                      .accentTextTheme
                      .subtitle1
                      .copyWith(fontSize: 18),
                )),
            BottomSheetItem(
                onTap: () {
                  LocalManager.setDraft(context.read(authProvider.state).user,
                      _formValue.toDraft(context.read(_draftProvider.state)));
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  '下書きに保存',
                  style: Theme.of(context)
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
                      color: Theme.of(context).disabledColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ))
          ],
          backGroundColor: Theme.of(context).primaryColor,
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
    _futureDraft = _getDrafts(context.read(authProvider.state).user);
    _controller = TextEditingController();
    _panelController = new PanelController();
    context.read(_savableProvider).set(_formValue.savable());
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
      style: Theme.of(context).textTheme.bodyText1.copyWith(
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
              Theme.of(context).textTheme.subtitle1.copyWith(fontSize: 15)),
    ));
    HabitLog log = _formValue.getLog();
    if (log != null) {
      _formWidgets.add(LogCard(
        log: log,
      ));
    }
    _formWidgets.add(SelectedImages());
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
    widgets.add(ImagePick());

    return Stack(
      children: [
        Container(
          color: Theme.of(context).primaryColor,
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
            color: Theme.of(context).primaryColor,
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
                width: MediaQuery.of(context).size.width,
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
                              color: Theme.of(context).primaryColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).shadowColor,
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
                                  color: Theme.of(context).accentColor,
                                ),
                              ),
                              Text(
                                'ライブラリ',
                                style: TextStyle(
                                    color: Theme.of(context).accentColor,
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
          max: 4, selected: context.read(imageSelectProvider.state));
      context.read(imageSelectProvider).setAll(assets);
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

  Widget getButton(
      {@required IconData icon,
      @required bool selected,
      @required BuildContext context,
      @required Function onTap,
      @required double iconSize}) {
    Color color = selected
        ? Theme.of(context).accentColor
        : Theme.of(context).disabledColor;
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

class SelectedImages extends HookWidget {
  @override
  Widget build(BuildContext context) {
    List<AssetEntity> imageAssets = useProvider(imageSelectProvider.state);
    List<ImageCard> images = <ImageCard>[];
    int i = 0;
    imageAssets.forEach((asset) {
      images.add(ImageCard(imageAsset: asset, isFirst: i == 0));
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

  ImageCard({@required this.imageAsset, @required this.isFirst});

  @override
  _ImageCardState createState() => _ImageCardState();
}

class _ImageCardState extends State<ImageCard> {
  Uint8List _image;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.imageAsset.thumbData.then((Uint8List _data) {
        setState(() {
          _image = _data;
        });
      });
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ImageCard oldWidget) {
    widget.imageAsset.thumbData.then((Uint8List _data) {
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
        color: Theme.of(context).disabledColor,
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
          color: Theme.of(context).disabledColor),
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
                      color: Theme.of(context).primaryColor),
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
  }
}

class ImagePick extends StatefulHookWidget {
  @override
  _ImagePickState createState() => _ImagePickState();
}

class _ImagePickState extends State<ImagePick>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<AssetEntity> selected = useProvider(imageSelectProvider.state);
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
                padding: EdgeInsets.symmetric(
                  horizontal: 24
                ),
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('ポストに写真を追加するには、Brebitによる写真へのアクセスを許可してください。',
                      style: Theme.of(context).textTheme.subtitle1.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w400
                      ),
                    ),
                    SizedBox(height: 32,),
                    GestureDetector(
                      child: Text('写真へのアクセスを許可',
                        style: TextStyle(
                          color: Theme.of(context).accentColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12
                        ),
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
                int index = selected.indexWhere((selectedFile) =>
                    selectedFile.relativePath + selectedFile.title ==
                    imageFile.relativePath + imageFile.title);
                cards.add(ImageTile(imageAsset: imageFile, index: index));
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
    if (await Permission.storage.request().isGranted) {
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
  final int index;

  ImageTile({@required this.imageAsset, @required this.index});

  @override
  _ImageTileState createState() => _ImageTileState();
}

class _ImageTileState extends State<ImageTile> {
  Uint8List image;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.imageAsset.thumbData.then((Uint8List data) {
        if (mounted) {
          setState(() {
            image = data;
          });
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (image == null) {
      child = Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).disabledColor,
      );
    } else {
      bool isSelected = false;
      if (widget.index >= 0) {
        isSelected = true;
      }
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

    bool isSelected = false;
    if (widget.index >= 0) {
      isSelected = true;
    }
    return InkWell(
        onTap: () {
          if (isSelected) {
            context.read(imageSelectProvider).unset(widget.imageAsset);
          } else {
            context.read(imageSelectProvider).set(widget.imageAsset);
          }
          context.read(_savableProvider).set(_formValue.savable());
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
                            color: Theme.of(context).primaryColor),
                        alignment: Alignment.center,
                        child: Text(
                          (widget.index + 1).toString(),
                          style: Theme.of(context)
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
      width: MediaQuery.of(context).size.width,
      color: Theme.of(context).primaryColor,
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
          style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 15)),
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
                  color: Theme.of(context).disabledColor,
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
      Uint8List d = await asset.thumbData;
      data.add(d);
    }
    return data;
  }
}

//
// class CreatePost extends StatefulWidget {
//
//   final CreatePostArguments args;
//   CreatePost({@required this.args});
//
//   @override
//   _CreatePostState createState() => _CreatePostState();
// }
//
// class _CreatePostState extends State<CreatePost> {
//   GlobalKey<FormState> _formState;
//   FormValue _formValue;
//   List<Widget> _images;
//
//   @override
//   void initState() {
//     super.initState();
//     _formState = new GlobalKey<FormState>();
//     _formValue = new FormValue();
//     _images = <Widget>[];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('新規作成'),
//         centerTitle: true,
//       ),
//       body: Container(
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               Form(
//                 key: _formState,
//                 child: TextFormField(
//                   maxLines: 10,
//                   validator: (value) {
//                     if (value.length == 0) {
//                       return '入力してください';
//                     } else {
//                       return null;
//                     }
//                   },
//                   onSaved: (value) {
//                     _formValue.inputData = value;
//                   },
//                   decoration: InputDecoration(hintText: 'あなたの記録を残しましょう'),
//                 ),
//               ),
//               _images.length > 0 ? Row(
//                 children: _images
//               ) : Container(
//                 height: 0,
//               ),
//               IconButton(
//                   icon: Icon(Icons.image_outlined),
//                   onPressed: () async {
//                     await pickImage();
//                   }),
//               TextButton(
//                 onPressed: () async {
//                   if (_formState.currentState.validate()) {
//                     _formState.currentState.save();
//
//                     List<File> files = [];
//                     final tempDir = await getApplicationDocumentsDirectory();
//                     for (Asset asset in _formValue.images) {
//                       final filePath =
//                       await FlutterAbsolutePath.getAbsolutePath(asset.identifier);
//                       File file = new File(filePath);
//                       int num = Random().nextInt(500000);
//                       Img.Image image = Img.decodeImage(File(filePath).readAsBytesSync());
//                       if ( ! ImageSizeGetter.isJpg(FileInput(file))) {
//                         file = new File(tempDir.path + '/$num.jpg')
//                           ..writeAsBytesSync(Img.encodeJpg(image));
//                       }
//                       while (file.lengthSync() > (2 * pow(1024, 2)) ) {
//                         Size size = ImageSizeGetter.getSize(FileInput(file));
//                         image = Img.copyResize(image, height: (size.height ~/ 2));
//                         file = new File(tempDir.path + '/$num.jpg')
//                           ..writeAsBytesSync(Img.encodeJpg(image));
//                       }
//                       files.add(file);
//                     }
//                     files.forEach((file) {
//                       print(file.lengthSync() / 1024);
//                     });
//                     if (_formValue.inputData.length > 0) {
//                       await PostApi.savePost(_formValue.inputData, files);
//                     }
//                     ApplicationRoutes.popUntil('/home');
//                   }
//                 },
//                 child: Text('保存'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> pickImage() async {
//     try {
//       _formValue.images = await MultiImagePicker.pickImages(
//         maxImages: 4,
//         enableCamera: true,
//         selectedAssets: _formValue.images,
//         cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
//         materialOptions: MaterialOptions(
//           actionBarColor: "#abcdef",
//           actionBarTitle: "Example App",
//           allViewTitle: "All Photos",
//           useDetailsView: false,
//           selectCircleStrokeColor: "#000000",
//         ),
//       );
//       List<Widget> images = <Widget>[];
//       for (int i = 0; i < _formValue.images.length; i++) {
//         String path = await FlutterAbsolutePath.getAbsolutePath(_formValue.images[i].identifier);
//         images.add(Expanded(
//           child: Container(
//             padding: EdgeInsets.symmetric(horizontal: 2),
//             child: Image.file(
//               File(path),
//               fit: BoxFit.cover,
//             ),
//           ),
//         ));
//       }
//       for (int i = 0; i < 4 - _formValue.images.length; i++) {
//         images.add(Expanded(
//           child: Container(
//
//           ),
//         ));
//       }
//       setState(() {
//         this._images = images;
//       });
//     } on Exception catch (e) {
//       throw e;
//     }
//   }
// }
