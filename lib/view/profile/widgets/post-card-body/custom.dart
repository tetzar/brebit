import '../../../../../route/route.dart';
import '../../../timeline/widget/log-card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class CustomBody extends StatelessWidget {
  final Map<String, dynamic> body;
  final List<String> imageUrls;
  final int num;

  CustomBody({@required this.body, @required this.num, this.imageUrls});

  @override
  Widget build(BuildContext context) {
    List<Widget> children = <Widget>[];
    if (body.containsKey('content')) {
      children.add(
          Text(
            body['content'],
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.bodyText1.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w400
            ),
          )
      );
    }

    if (body.containsKey('habit_log')) {
      children.add(
          Container(
            margin: EdgeInsets.only(top: 4),
            child: LogCard(log: body['habit_log'],),
          )
      );
    }
    if (imageUrls.length > 0) {
      children.add(
        ImageGrid(imageUrls: imageUrls, num: num),
      );
    }
    return Container(
        width: double.infinity,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children
        ));
  }
}

class ImageGrid extends StatefulWidget {
  final List<String> imageUrls;
  final int num;

  ImageGrid({@required this.imageUrls, @required this.num});

  @override
  _ImageGridState createState() => _ImageGridState();
}

class _ImageGridState extends State<ImageGrid> {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        height: 160,
        margin: EdgeInsets.only(top: 4),
        decoration:
            BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(8))),
        child: getGrid());
  }

  Widget getGrid() {
    switch (widget.imageUrls.length) {
      case 1:
        return GestureDetector(
          onTap: () {
            int tag = widget.num * 10;
            open(context, tag);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: Hero(
              tag: widget.num * 10,
              child: CachedNetworkImage(
                fit: BoxFit.cover,
                imageUrl: widget.imageUrls[0],
                placeholder: (context, url) => Container(
                  color: Theme.of(context).backgroundColor,
                ),
                imageBuilder: (BuildContext context,
                    ImageProvider imageProvider) {
                  return Container(
                      width: double.infinity,
                      height: 78,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover),
                      ));
                },
              ),
            ),
          ),
        );
        break;
      case 2:
        return Row(
          children: [
            Expanded(
              child: Container(
                height: double.infinity,
                padding: EdgeInsets.only(right: 2),
                child: GestureDetector(
                  onTap: () {
                    int tag = widget.num * 10;
                    open(context, tag);
                  },
                  child: Hero(
                    tag: widget.num * 10,
                    child: CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: widget.imageUrls[0],
                      placeholder: (context, url) => Container(
                        color: Theme.of(context).backgroundColor,
                      ),
                      imageBuilder: (BuildContext context,
                          ImageProvider imageProvider) {
                        return Container(
                            width: double.infinity,
                            height: 78,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                              ),
                              image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover),
                            ));
                      },
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: double.infinity,
                padding: EdgeInsets.only(left: 2),
                child: GestureDetector(
                  onTap: () {
                    int tag = widget.num * 10 + 1;
                    open(context, tag);
                  },
                  child: Hero(
                    tag: widget.num * 10 + 1,
                    child: CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: widget.imageUrls[1],
                      placeholder: (context, url) => Container(
                        color: Theme.of(context).backgroundColor,
                      ),
                      imageBuilder: (BuildContext context,
                          ImageProvider imageProvider) {
                        return Container(
                            width: double.infinity,
                            height: 78,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(8),
                                  topRight: Radius.circular(8)
                              ),
                              image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover),
                            ));
                      },
                    ),
                  ),
                ),
              ),
            )
          ],
        );
        break;
      case 3:
        return Row(
          children: [
            Expanded(
              child: Container(
                height: double.infinity,
                padding: EdgeInsets.only(right: 2),
                child: GestureDetector(
                  onTap: () {
                    int tag = widget.num * 10;
                    open(context, tag);
                  },
                  child: Hero(
                    tag: widget.num * 10 ,
                    child: CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: widget.imageUrls[0],
                      placeholder: (context, url) => Container(
                        color: Theme.of(context).backgroundColor,
                      ),
                      imageBuilder: (BuildContext context,
                          ImageProvider imageProvider) {
                        return Container(
                            width: double.infinity,
                            height: 78,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  topLeft: Radius.circular(8)
                              ),
                              image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover),
                            ));
                      },
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: double.infinity,
                padding: EdgeInsets.only(left: 2),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(bottom: 2),
                      height: 80,
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          int tag = widget.num * 10 + 1;
                          open(context, tag);
                        },
                        child: Hero(
                          tag: widget.num * 10 + 1,
                          child: CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: widget.imageUrls[1],
                            placeholder: (context, url) => Container(
                              color: Theme.of(context).backgroundColor,
                            ),
                            imageBuilder: (BuildContext context,
                                ImageProvider imageProvider) {
                              return Container(
                                  width: double.infinity,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(8)),
                                    image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover),
                                  ));
                            },
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(top: 2),
                      height: 80,
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          int tag = widget.num * 10 + 2;
                          open(context, tag);
                        },
                        child: Hero(
                          tag: widget.num * 10 + 2,
                          child: CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: widget.imageUrls[2],
                            placeholder: (context, url) => Container(
                              color: Theme.of(context).backgroundColor,
                            ),
                            imageBuilder: (BuildContext context,
                                ImageProvider imageProvider) {
                              return Container(
                                  width: double.infinity,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        bottomRight: Radius.circular(8)),
                                    image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover),
                                  ));
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        );
        break;
      default:
        return Row(
          children: [
            Expanded(
              child: Container(
                height: double.infinity,
                padding: EdgeInsets.only(right: 2),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(bottom: 2),
                      height: 80,
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          int tag = widget.num * 10;
                          open(context, tag);
                        },
                        child: Hero(
                          tag: widget.num * 10,
                          child: CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: widget.imageUrls[0],
                            placeholder: (context, url) => Container(
                              color: Theme.of(context).backgroundColor,
                            ),
                            imageBuilder: (BuildContext context,
                                ImageProvider imageProvider) {
                              return Container(
                                  width: double.infinity,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8)),
                                    image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover),
                                  ));
                            },
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(top: 2),
                      height: 80,
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          int tag = widget.num * 10 + 1;
                          open(context, tag);
                        },
                        child: Hero(
                          tag: widget.num * 10 + 1,
                          child: CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: widget.imageUrls[1],
                            placeholder: (context, url) => Container(
                              color: Theme.of(context).backgroundColor,
                            ),
                            imageBuilder: (BuildContext context,
                                ImageProvider imageProvider) {
                              return Container(
                                  width: double.infinity,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(8)),
                                    image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover),
                                  ));
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: double.infinity,
                padding: EdgeInsets.only(left: 2),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(bottom: 2),
                      height: 80,
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          int tag = widget.num * 10 + 2;
                          open(context, tag);
                        },
                        child: Hero(
                          tag: widget.num * 10 + 2,
                          child: CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: widget.imageUrls[2],
                            placeholder: (context, url) => Container(
                              color: Theme.of(context).backgroundColor,
                            ),
                            imageBuilder: (BuildContext context,
                                ImageProvider imageProvider) {
                              return Container(
                                  width: double.infinity,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(8)),
                                    image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover),
                                  ));
                            },
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(top: 2),
                      height: 80,
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          int tag = widget.num * 10 + 3;
                          open(context, tag);
                        },
                        child: Hero(
                          tag: widget.num * 10 + 3,
                          child: CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: widget.imageUrls[3],
                            placeholder: (context, url) => Container(
                              color: Theme.of(context).backgroundColor,
                            ),
                            imageBuilder: (BuildContext context,
                                ImageProvider imageProvider) {
                              return Container(
                                  width: double.infinity,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        bottomRight: Radius.circular(8)),
                                    image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover),
                                  ));
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        );
        break;
    }
  }

  void open(BuildContext ctx, int tag) {
    ApplicationRoutes.materialKey.currentState.push(PageTransition(
      type: PageTransitionType.fade,
      child: GalleryPhotoViewWrapper(
        galleryItems: this.widget.imageUrls,
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        tag: tag,
        scrollDirection: Axis.horizontal,
      ),
    ));
  }
}

class GalleryPhotoViewWrapper extends StatefulWidget {
  final List<String> galleryItems;
  final BoxDecoration backgroundDecoration;
  final int tag;
  final Axis scrollDirection;
  final PageController pageController;

  GalleryPhotoViewWrapper(
      {@required this.galleryItems,
      @required this.backgroundDecoration,
      @required this.tag,
      @required this.scrollDirection})
      : pageController = new PageController(initialPage: tag % 10);

  @override
  _GalleryPhotoViewWrapperState createState() =>
      _GalleryPhotoViewWrapperState();
}

class _GalleryPhotoViewWrapperState extends State<GalleryPhotoViewWrapper> {
  int currentIndex;

  @override
  void initState() {
    currentIndex = widget.tag % 10;
    super.initState();
  }

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: widget.backgroundDecoration,
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: PhotoViewGallery.builder(
          scrollPhysics: const BouncingScrollPhysics(),
          builder: _buildItem,
          itemCount: widget.galleryItems.length,
          backgroundDecoration: widget.backgroundDecoration,
          pageController: widget.pageController,
          onPageChanged: onPageChanged,
          scrollDirection: widget.scrollDirection,
        ),
      ),
    );
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    final String url = widget.galleryItems[index];
    return PhotoViewGalleryPageOptions.customChild(
      child: CachedNetworkImage(
        imageUrl: url,
      ),
      initialScale: PhotoViewComputedScale.contained,
      // minScale: PhotoViewComputedScale.contained * (0.5 + index / 10),
      // maxScale: PhotoViewComputedScale.covered * 4.1,
      heroAttributes:
          PhotoViewHeroAttributes(tag: (widget.tag ~/ 10) * 10 + index),
    );
  }
}
