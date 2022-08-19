import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:brebit/library/image-manager.dart';
import 'package:brebit/view/timeline/create_post.dart';
import 'package:flutter/material.dart';
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

  ImageAssetProviderState(
      {required this.entities,
      required this.selected,
      required this.fileOfSelected});

  ImageAssetProviderState copyWith(
      {List<AssetEntity>? selected,
      List<AssetPathEntity>? entities,
      List<File>? fileOfSelected}) {
    return ImageAssetProviderState(
        entities: entities ?? this.entities,
        selected: selected ?? this.selected,
        fileOfSelected: fileOfSelected ?? this.fileOfSelected);
  }
}

class ImageAssetProvider extends StateNotifier<ImageAssetProviderState> {
  ImageAssetProvider(ImageAssetProviderState state) : super(state);

  late int max;

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

  List<AssetPathEntity> getPaths() {
    return state.entities;
  }

  List<AssetEntity> getSelected() {
    return this.state.selected;
  }

  bool isSetImage(File file) {
    return getIndex(file) >= 0;
  }

  Future<bool> addSelected(AssetEntity asset) async {
    if (state.selected.length >= 4) return false;
    File? file = await ImageManager.assetEntityToFile(asset);
    if (file == null) return false;
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

final imageAssetProvider = StateNotifierProvider.autoDispose((ref) =>
    ImageAssetProvider(ImageAssetProviderState(
        entities: [], fileOfSelected: [], selected: [])));

class MyMultiImagePicker extends StatefulHookConsumerWidget {
  final int max;
  final List<AssetEntity> selected;

  MyMultiImagePicker({required this.max, required this.selected});

  @override
  _MyMultiImagePickerState createState() => _MyMultiImagePickerState();

  static Future<List<AssetEntity>> pickImages({
    required int max,
    required List<AssetEntity> selected,
  }) async {
    List<AssetEntity> result = await ApplicationRoutes.push(MaterialPageRoute(
        builder: (context) => MyMultiImagePicker(
              max: max,
              selected: selected,
            )));
    return result;
  }
}

class _MyMultiImagePickerState extends ConsumerState<MyMultiImagePicker> {
  @override
  void initState() {
    ref
        .read(imageAssetProvider.notifier)
        .initialize(widget.selected, widget.max);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(imageAssetProvider);
    String title = getTitle(ref);
    List<AssetPathEntity> paths =
        ref.read(imageAssetProvider.notifier).getPaths();
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
                color: Theme.of(context).appBarTheme.iconTheme?.color,
              ),
              onPressed: () {
                saveImage(ref);
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

  String getTitle(WidgetRef _ref) {
    return '画像を選択  ${_ref.read(imageAssetProvider.notifier).getSelectedCount()}/${widget.max}';
  }

  void saveImage(WidgetRef ref) {
    ApplicationRoutes.pop(ref.read(imageAssetProvider.notifier).getSelected());
  }
}

class GalleryTile extends StatefulWidget {
  final AssetPathEntity pathEntity;
  final int max;

  GalleryTile({required this.pathEntity, required this.max});

  @override
  _GalleryTileState createState() => _GalleryTileState();
}

class _GalleryTileState extends State<GalleryTile> {
  Uint8List? _data;

  @override
  void initState() {
    widget.pathEntity
        .getAssetListRange(start: 0, end: 1)
        .then((List<AssetEntity> list) async {
      Uint8List? _firstImageData = await list.first.thumbnailDataWithSize(
          ThumbnailSize(ThumbSize.WIDTH, ThumbSize.HEIGHT),
          quality: ThumbSize.QUALITY);
      setState(() {
        _data = _firstImageData;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? imageData = _data;
    return InkWell(
      onTap: () async {
        List<AssetEntity> assets = await ApplicationRoutes.push(
            MaterialPageRoute(
                builder: (BuildContext context) => AssetPicker(
                    pathEntity: widget.pathEntity, max: widget.max)));
        ApplicationRoutes.pop(assets);
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
                  image: imageData == null
                      ? null
                      : DecorationImage(
                          image: MemoryImage(imageData), fit: BoxFit.cover)),
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
                          ?.copyWith(fontSize: 12),
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

class AssetPicker extends ConsumerStatefulWidget {
  final int max;
  final AssetPathEntity pathEntity;

  AssetPicker({required this.pathEntity, required this.max});

  @override
  _AssetPickerState createState() => _AssetPickerState();
}

class _AssetPickerState extends ConsumerState<AssetPicker> {
  final int pageCount = 50;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Future<List<AssetEntity>> _future =
        widget.pathEntity.getAssetListPaged(page: 0, size: pageCount);

    return FutureBuilder(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold();
        } else {
          return Scaffold(
            appBar: AppBar(
              title:
                  _ImagePickerAppBarTitle(widget.pathEntity.name, widget.max),
              leading: MyBackButton(),
              actions: [
                IconButton(
                    icon: Icon(
                      Icons.check,
                      color: Theme.of(context).appBarTheme.iconTheme?.color,
                    ),
                    onPressed: () {
                      saveImage(ref);
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

  void saveImage(WidgetRef ref) {
    ApplicationRoutes.pop(ref.read(imageAssetProvider.notifier).getSelected());
  }
}

class _ImagePickerAppBarTitle extends ConsumerWidget {
  const _ImagePickerAppBarTitle(this.pathName, this.max, {Key? key})
      : super(key: key);
  final String pathName;
  final int max;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(imageAssetProvider);
    int selectedCount =
        ref.read(imageAssetProvider.notifier).getSelectedCount();
    return Text(
      pathName + '  ' + '($selectedCount/$max)',
    );
  }
}

class ImageTiles extends ConsumerStatefulWidget {
  final List<AssetEntity> assets;
  final int pageCount;
  final int max;
  final AssetPathEntity pathEntity;

  ImageTiles(
      {required this.assets,
      required this.pageCount,
      required this.max,
      required this.pathEntity});

  @override
  _ImageTilesState createState() => _ImageTilesState();
}

class _ImageTilesState extends ConsumerState<ImageTiles> {
  bool nowLoading = false;
  bool noMoreContent = false;
  int loaded = 0;
  int tapCount = 0;
  late ScrollController _scrollController;
  late List<AssetEntity> assets;
  late StreamController<int> imageSelectedStream;

  @override
  void initState() {
    loaded = 0;
    tapCount = 0;
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
    imageSelectedStream = StreamController.broadcast();
    super.initState();
  }

  @override
  void dispose() {
    imageSelectedStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> cards = <Widget>[];
    for (AssetEntity asset in assets) {
      cards.add(AssetPickerTile(
        asset: asset,
        indexCallback: getIndex,
        onSelect: (AssetEntity asset) {
          return onSelect(asset, ref);
        },
        imageSelectedStream: imageSelectedStream,
      ));
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

  Future<bool> setImage(WidgetRef ref, AssetEntity image) async {
    return await ref.read(imageAssetProvider.notifier).addSelected(image);
  }

  int getSameImageIndex(WidgetRef ref, File imageFile) {
    return ref.read(imageAssetProvider.notifier).getIndex(imageFile);
  }

  Future<File?> getFileFromAssetEntity(AssetEntity image) async {
    return await ImageManager.assetEntityToFile(image);
  }

  Future<int> getIndex(WidgetRef ref, AssetEntity asset) async {
    File? file = await getFileFromAssetEntity(asset);
    if (file == null) return -1;
    return getSameImageIndex(ref, file);
  }

  bool unsetImage(WidgetRef ref, File file) {
    return ref.read(imageAssetProvider.notifier).removeSelected(file);
  }

  Future<int> onSelect(AssetEntity asset, WidgetRef ref) async {
    File? file = await ImageManager.assetEntityToFile(asset);
    if (file == null) return -1;
    tapCount++;
    if (ref.read(imageAssetProvider.notifier).isSetImage(file)) {
      unsetImage(ref, file);
      imageSelectedStream.sink.add(tapCount);
      return -1;
    } else {
      if (await setImage(ref, asset)) return await getIndex(ref, asset);
      imageSelectedStream.sink.add(tapCount);
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
            .getAssetListPaged(page: ++loaded, size: widget.pageCount);
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
typedef IndexCallback = Future<int> Function(WidgetRef, AssetEntity);

class AssetPickerTile extends ConsumerStatefulWidget {
  final AssetSelectCallback onSelect;
  final IndexCallback indexCallback;
  final AssetEntity asset;
  final StreamController imageSelectedStream;

  AssetPickerTile(
      {required this.asset,
      required this.onSelect,
      required this.indexCallback,
      required this.imageSelectedStream});

  @override
  _AssetPickerTileState createState() => _AssetPickerTileState();
}

class _AssetPickerTileState extends ConsumerState<AssetPickerTile> {
  Uint8List? _data;
  int _index = -1;
  late Future<int> futureIndex;

  @override
  void initState() {
    widget.asset
        .thumbnailDataWithSize(
            ThumbnailSize(
              ThumbSize.WIDTH,
              ThumbSize.HEIGHT,
            ),
            quality: ThumbSize.QUALITY)
        .then((assetData) {
      setState(() {
        _data = assetData;
      });
    });
    widget.indexCallback(ref, widget.asset).then((index) {
      setState(() {
        _index = index;
      });
    });
    widget.imageSelectedStream.stream.listen((_) {
      widget.indexCallback(ref, widget.asset).then((index) {
        if (index != _index) {
          setState(() {
            _index = index;
          });
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? imageData = _data;
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
                    image: imageData != null
                        ? DecorationImage(
                            image: MemoryImage(
                              imageData,
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
                            : Theme.of(context).colorScheme.secondary),
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
        ));
  }
}
