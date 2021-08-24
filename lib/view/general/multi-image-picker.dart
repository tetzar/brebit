import 'dart:io';
import 'dart:typed_data';

import '../../../route/route.dart';
import '../widgets/back-button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

typedef ImagePickerSavedCallback = Future<List<AssetEntity>> Function(
    List<AssetEntity>);

class ImageAssetProviderState {
  List<AssetPathEntity> entities;
  List<AssetEntity> selected;

  ImageAssetProviderState({this.entities, this.selected});

  ImageAssetProviderState copyWith(
      {List<AssetEntity> selected, List<AssetPathEntity> entities}) {
    return ImageAssetProviderState(
        entities: entities != null ? entities : this.entities,
        selected: selected != null ? selected : this.selected);
  }
}

class ImageAssetProvider extends StateNotifier<ImageAssetProviderState> {
  ImageAssetProvider(ImageAssetProviderState state) : super(state);

  int getSelectedCount() {
    return this.state.selected.length;
  }

  Future<void> initialize(List<AssetEntity> selected) async {
    List<AssetPathEntity> entities = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
    );
    entities.sort((a, b) => a.assetCount > b.assetCount ? -1 : 1);
    ImageAssetProviderState _newState = new ImageAssetProviderState();
    _newState.entities = entities;
    _newState.selected = selected;
    this.state = _newState;
  }

  bool initialized() {
    return state != null;
  }

  List<AssetPathEntity> getPaths() {
    if (state != null) {
      if (state.entities != null) {
        return state.entities;
      }
    }
    return <AssetPathEntity>[];
  }

  List<AssetEntity> getSelected() {
    if (this.state != null) {
      if (this.state.selected != null) {
        return this.state.selected;
      }
    }
    return <AssetEntity>[];
  }

  void setSelected(List<AssetEntity> _selected) {
    state = state.copyWith(selected: _selected);
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
    context.read(imageAssetProvider).initialize(widget.selected);
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
      if (Platform.isAndroid) {
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
      Uint8List _firstImageData = await list.first.thumbData;
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
        List<AssetEntity> assets = await ApplicationRoutes.push(MaterialPageRoute(
            builder: (BuildContext context) => AssetPicker(
                pathEntity: widget.pathEntity,
                selected: context.read(imageAssetProvider).getSelected(),
                max: widget.max)));
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
  final List<AssetEntity> selected;
  final int max;
  final AssetPathEntity pathEntity;

  AssetPicker(
      {@required this.pathEntity, @required this.selected, @required this.max});

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
              selected: widget.selected,
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

  void saveImage(BuildContext context){
    ApplicationRoutes.pop(context.read(imageAssetProvider).getSelected());
  }
}

class ImageTiles extends StatefulWidget {
  final List<AssetEntity> selected;
  final List<AssetEntity> assets;
  final int pageCount;
  final int max;
  final AssetPathEntity pathEntity;

  ImageTiles(
      {@required this.selected,
      @required this.assets,
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
  List<AssetEntity> _selected;

  @override
  void initState() {
    loaded = 0;
    this._selected = widget.selected;
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

  int getIndex(AssetEntity asset) {
    int index = this._selected.indexWhere((selectedAsset) =>
        selectedAsset.relativePath + selectedAsset.title ==
        asset.relativePath + asset.title);
    return index;
  }

  int onSelect(AssetEntity asset, BuildContext context) {
    int index = getIndex(asset);
    if (index < 0) {
      if (_selected.length < widget.max) {
        this._selected.add(asset);
        context.read(imageAssetProvider).setSelected(this._selected);
        return _selected.length - 1;
      }
      return -1;
    } else {
      this._selected.removeWhere((selectedAsset) =>
          selectedAsset.relativePath + selectedAsset.title ==
          asset.relativePath + asset.title);
      context.read(imageAssetProvider).setSelected(this._selected);
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

typedef AssetSelectCallback = int Function(AssetEntity);
typedef IndexCallback = int Function(AssetEntity);

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
  int _index;

  @override
  void initState() {
    _index = widget.indexCallback(widget.asset);
    widget.asset.thumbData.then((assetData) {
      setState(() {
        _data = assetData;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _index = widget.onSelect(widget.asset);
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
      ),
    );
  }
}
