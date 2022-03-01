import 'dart:io';
import 'dart:typed_data';

import 'package:brebit/library/image-manager.dart';
import 'package:brebit/view/timeline/create_post.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../route/route.dart';
import '../widgets/back-button.dart';

typedef ImagePickerSavedCallback = Future<List<AssetEntity>> Function(
    List<AssetEntity>);

class ImageAssetProviderState {
  List<AssetPathEntity> entities;
  List<AssetEntity> selected;
  List<File> fileOfSelected;

  ImageAssetProviderState({this.entities, this.selected, this.fileOfSelected});

  ImageAssetProviderState copyWith(
      {List<AssetEntity> selected,
      List<AssetPathEntity> entities,
      List<File> fileOfSelected}) {
    return ImageAssetProviderState(
        entities: entities ?? this.entities,
        selected: selected ?? this.selected,
        fileOfSelected: fileOfSelected ?? this.selected);
  }
}

class ImageAssetProvider extends StateNotifier<ImageAssetProviderState> {
  ImageAssetProvider(ImageAssetProviderState state) : super(state);

  int max;

  int getSelectedCount() {
    return this.state.selected.length;
  }

  Future<void> initialize(List<AssetEntity> selected, int max) async {
    List<AssetPathEntity> entities = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
    );
    entities.sort((a, b) => a.assetCount > b.assetCount ? -1 : 1);
    this.state = new ImageAssetProviderState(
        entities: entities,
        selected: selected,
        fileOfSelected: await ImageManager.assetEntitiesToFiles(selected));
    max = max;
  }

  bool initialized() {
    return state != null;
  }

  List<AssetPathEntity> getPaths() {
    if (state != null && state.entities != null) return state.entities;
    return <AssetPathEntity>[];
  }

  List<AssetEntity> getSelected() {
    if (this.state != null && this.state.selected != null)
      return this.state.selected;
    return <AssetEntity>[];
  }

  bool isSetImage(File file) {
    return getIndex(file) >= 0;
  }

  Future<bool> addSelected(AssetEntity asset) async {
    if (!initialized() || state.selected.length >= 4) return false;
    File file = await ImageManager.assetEntityToFile(asset);
    if (isSetImage(file)) return false;
    state.selected.add(asset);
    state.fileOfSelected.add(file);
    state = state;
    return true;
  }

  Future<void> setSelected(List<AssetEntity> _selected) async {
    state = state.copyWith(
        selected: _selected,
        fileOfSelected: await ImageManager.assetEntitiesToFiles(_selected));
  }

  bool removeSelected(File file) {
    int index = state.fileOfSelected.indexWhere((f) => f.path == file.path);
    if (index < 0) return false;
    state.fileOfSelected.removeAt(index);
    state.selected.removeAt(index);
    state = state;
    return true;
  }

  int getIndex(File file) {
    return state.fileOfSelected.indexWhere((f) => f.path == file.path);
  }
}

final imageAssetProvider =
    StateNotifierProvider.autoDispose((ref) => ImageAssetProvider(null));

class MyMultiImagePicker extends StatefulHookWidget {
  final int max;
  final List<AssetEntity> selected;

  MyMultiImagePicker({@required this.max, @required this.selected});

  @override
  _MyMultiImagePickerState createState() => _MyMultiImagePickerState();

  static Future<List<AssetEntity>> pickImages({
    int max,
    List<AssetEntity> selected,
  }) async {
    List<AssetEntity> result = await ApplicationRoutes.push(MaterialPageRoute(
        builder: (context) => MyMultiImagePicker(
              max: max,
              selected: selected,
            )));
    return result;
  }
}

class _MyMultiImagePickerState extends State<MyMultiImagePicker> {
  @override
  void initState() {
    context.read(imageAssetProvider).initialize(widget.selected, widget.max);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    useProvider(imageAssetProvider.state);
    if (!context.read(imageAssetProvider).initialized()) {
      return Scaffold();
    } else {
      String title = getTitle(context);
      List<AssetPathEntity> paths = context.read(imageAssetProvider).getPaths();
      return Scaffold(
        appBar: AppBar(
          leading: MyBackButton(),
          title: Text(
            title,
          ),
          actions: [
            IconButton(
                icon: Icon(
                  Icons.check,
                  color: Theme.of(context).appBarTheme.iconTheme.color,
                ),
                onPressed: () {
                  saveImage(context);
                })
          ],
        ),
        body: ListView.builder(
          itemCount: paths.length,
          itemBuilder: (BuildContext context, int index) {
            return GalleryTile(
              pathEntity: paths[index],
              max: widget.max,
            );
          },
        ),
      );
    }
  }

  String getTitle(BuildContext _ctx) {
    return '画像を選択  ${_ctx.read(imageAssetProvider).getSelectedCount()}/${widget.max}';
  }

  void saveImage(BuildContext context) {
    ApplicationRoutes.pop(context.read(imageAssetProvider).getSelected());
  }
}

class GalleryTile extends StatefulWidget {
  final AssetPathEntity pathEntity;
  final int max;

  GalleryTile({@required this.pathEntity, @required this.max});

  @override
  _GalleryTileState createState() => _GalleryTileState();
}

class _GalleryTileState extends State<GalleryTile> {
  Uint8List _data;

  @override
  void initState() {
    widget.pathEntity
        .getAssetListRange(start: 0, end: 1)
        .then((List<AssetEntity> list) async {
      Uint8List _firstImageData = await list.first.thumbDataWithSize(
          ThumbSize.WIDTH, ThumbSize.HEIGHT,
          quality: ThumbSize.QUALITY);
      setState(() {
        _data = _firstImageData;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        List<AssetEntity> assets = await ApplicationRoutes.push(
            MaterialPageRoute(
                builder: (BuildContext context) => AssetPicker(
                    pathEntity: widget.pathEntity, max: widget.max)));
        if (assets != null) {
          ApplicationRoutes.pop(assets);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
        ),
        height: 88,
        width: double.infinity,
        child: Row(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 88,
              height: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.transparent,
                  image: _data == null
                      ? null
                      : DecorationImage(
                          image: MemoryImage(_data), fit: BoxFit.cover)),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pathEntity.name,
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Text(
                      widget.pathEntity.assetCount.toString(),
                      style: Theme.of(context)
                          .textTheme
                          .subtitle1
                          .copyWith(fontSize: 12),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class AssetPicker extends StatefulWidget {
  final int max;
  final AssetPathEntity pathEntity;

  AssetPicker({@required this.pathEntity, @required this.max});

  @override
  _AssetPickerState createState() => _AssetPickerState();
}

class _AssetPickerState extends State<AssetPicker> {
  final int pageCount = 50;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Future<List<AssetEntity>> _future =
        widget.pathEntity.getAssetListPaged(0, pageCount);

    return FutureBuilder(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold();
        } else {
          return Scaffold(
            appBar: AppBar(
              title: HookBuilder(builder: (context) {
                useProvider(imageAssetProvider.state);
                int selectedCount =
                    context.read(imageAssetProvider).getSelectedCount();
                return Text(
                  widget.pathEntity.name +
                      '  ' +
                      '($selectedCount/${widget.max})',
                );
              }),
              leading: MyBackButton(),
              actions: [
                IconButton(
                    icon: Icon(
                      Icons.check,
                      color: Theme.of(context).appBarTheme.iconTheme.color,
                    ),
                    onPressed: () {
                      saveImage(context);
                    })
              ],
            ),
            body: ImageTiles(
              assets: snapshot.data,
              pageCount: pageCount,
              max: widget.max,
              pathEntity: widget.pathEntity,
            ),
          );
        }
      },
    );
  }

  void saveImage(BuildContext context) {
    ApplicationRoutes.pop(context.read(imageAssetProvider).getSelected());
  }
}

class ImageTiles extends StatefulWidget {
  final List<AssetEntity> assets;
  final int pageCount;
  final int max;
  final AssetPathEntity pathEntity;

  ImageTiles(
      {@required this.assets,
      @required this.pageCount,
      @required this.max,
      @required this.pathEntity});

  @override
  _ImageTilesState createState() => _ImageTilesState();
}

class _ImageTilesState extends State<ImageTiles> {
  bool nowLoading;
  bool noMoreContent;
  int loaded;
  ScrollController _scrollController;
  List<AssetEntity> assets;

  @override
  void initState() {
    loaded = 0;
    _scrollController = new ScrollController();
    nowLoading = false;
    assets = widget.assets;
    if (assets.length < widget.pageCount) {
      noMoreContent = true;
    } else {
      noMoreContent = false;
    }
    _scrollController.addListener(() {
      if (!nowLoading) {
        reloadOlder();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> cards = <Widget>[];
    for (AssetEntity asset in assets) {
      cards.add(AssetPickerTile(
          asset: asset,
          indexCallback: getIndex,
          onSelect: (AssetEntity asset) {
            return onSelect(asset, context);
          }));
    }
    return Container(
      width: MediaQuery.of(context).size.width,
      child: GridView.count(
        controller: _scrollController,
        crossAxisCount: 3,
        scrollDirection: Axis.vertical,
        cacheExtent: 2,
        children: cards,
      ),
    );
  }

  bool sameImage(File imgFile1, File imgFile2) {
    return imgFile1.path == imgFile2.path;
  }

  Future<bool> setImage(BuildContext context, AssetEntity image) async {
    return await context.read(imageAssetProvider).addSelected(image);
  }

  int getSameImageIndex(BuildContext context, File imageFile) {
    return context.read(imageAssetProvider).getIndex(imageFile);
  }

  Future<File> getFileFromAssetEntity(AssetEntity image) async {
    return await ImageManager.assetEntityToFile(image);
  }

  Future<int> getIndex(BuildContext context, AssetEntity asset) async {
    return getSameImageIndex(context, await getFileFromAssetEntity(asset));
  }

  bool unsetImage(BuildContext context, File file) {
    return context.read(imageAssetProvider).removeSelected(file);
  }

  Future<int> onSelect(AssetEntity asset, BuildContext context) async {
    File file = await ImageManager.assetEntityToFile(asset);
    if (context.read(imageAssetProvider).isSetImage(file)) {
      unsetImage(context, file);
      return -1;
    } else {
      if (await setImage(context, asset)) return await getIndex(context, asset);
      return -1;
    }
  }

  Future<void> reloadOlder() async {
    if (!noMoreContent) {
      if ((_scrollController.position.maxScrollExtent -
                  _scrollController.position.pixels) <
              50 &&
          !nowLoading) {
        nowLoading = true;
        List<AssetEntity> newAssets = await widget.pathEntity
            .getAssetListPaged(++loaded, widget.pageCount);
        nowLoading = false;
        print(newAssets.length.toString());
        if (newAssets.length < widget.pageCount) {
          noMoreContent = true;
        }
        setState(() {
          assets.addAll(newAssets);
        });
      }
    }
  }
}

typedef AssetSelectCallback = Future<int> Function(AssetEntity);
typedef IndexCallback = Future<int> Function(BuildContext, AssetEntity);

class AssetPickerTile extends StatefulWidget {
  final AssetSelectCallback onSelect;
  final IndexCallback indexCallback;
  final AssetEntity asset;

  AssetPickerTile(
      {@required this.asset,
      @required this.onSelect,
      @required this.indexCallback});

  @override
  _AssetPickerTileState createState() => _AssetPickerTileState();
}

class _AssetPickerTileState extends State<AssetPickerTile> {
  Uint8List _data;
  int _index = -1;
  Future<int> futureIndex;

  @override
  void initState() {
    widget.asset
        .thumbDataWithSize(ThumbSize.WIDTH, ThumbSize.HEIGHT,
            quality: ThumbSize.QUALITY)
        .then((assetData) {
      setState(() {
        _data = assetData;
      });
    });
    widget.indexCallback(context, widget.asset).then((index){
      setState(() {
        _index = index;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        _index = await widget.onSelect(widget.asset);
        setState(() {});
      },
      child: Container(
        width: double.infinity,
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 0),
                height: double.infinity,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  image: _data != null
                      ? DecorationImage(
                      image: MemoryImage(
                        _data,
                      ),
                      colorFilter: ColorFilter.mode(
                          _index < 0
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          BlendMode.modulate),
                      fit: BoxFit.cover)
                      : null,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  height: 20,
                  width: 20,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                      color: _index < 0
                          ? Colors.transparent
                          : Theme.of(context).accentColor),
                  alignment: Alignment.center,
                  child: Text(
                    _index < 0 ? '' : (_index + 1).toString(),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w400),
                  ),
                ),
              )
            ],
          ),
        ),
      )
    );
  }
}
