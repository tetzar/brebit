import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class GalleryPhotoViewWrapper extends StatefulWidget {
  final List<String> galleryItems;
  final BoxDecoration backgroundDecoration;
  final String tag;
  final Axis scrollDirection;
  final PageController pageController;

  GalleryPhotoViewWrapper(
      {@required this.galleryItems,
      @required this.backgroundDecoration,
      @required this.tag,
      @required this.scrollDirection})
      : pageController = new PageController(initialPage: galleryItems.indexWhere((element) => element == tag));

  @override
  _GalleryPhotoViewWrapperState createState() =>
      _GalleryPhotoViewWrapperState();
}

class _GalleryPhotoViewWrapperState extends State<GalleryPhotoViewWrapper> {

  Offset beginningDragPosition = Offset.zero;
  Offset currentDragPosition = Offset.zero;
  PhotoViewScaleState scaleState = PhotoViewScaleState.initial;
  int photoViewAnimationDurationMilliSec = 0;
  double barsOpacity = 1.0;

  bool isHorizontalScrolling = false;

  @override
  void initState() {
    widget.pageController.addListener(() {
      double page  = widget.pageController.page;
      isHorizontalScrolling = ((page - page.round().toDouble()).abs() > 0.001);
    });
    super.initState();
  }

  double get photoViewScale {
    return max(1.0 - currentDragPosition.distance * 0.001, 0.8);
  }

  Matrix4 get photoViewTransform {
    final translationTransform = Matrix4.translationValues(
      currentDragPosition.dx,
      currentDragPosition.dy,
      0.0,
    );

    final scaleTransform = Matrix4.diagonal3Values(
      photoViewScale,
      photoViewScale,
      1.0,
    );

    return translationTransform * scaleTransform;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildImage(context),
    );
  }

  Widget _buildImage(BuildContext context) {
    return Container(
      color: Colors.black,
      child: GestureDetector(
        onTap: onTapPhotoView,
        onVerticalDragStart: scaleState == PhotoViewScaleState.initial
            ? onVerticalDragStart
            : null,
        onVerticalDragUpdate: scaleState == PhotoViewScaleState.initial
            ? onVerticalDragUpdate
            : null,
        onVerticalDragEnd: scaleState == PhotoViewScaleState.initial
            ? onVerticalDragEnd
            : null,
        child: AnimatedContainer(
          duration: Duration(milliseconds: photoViewAnimationDurationMilliSec),
          transform: photoViewTransform,
          child: PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: _buildItem,
            itemCount: widget.galleryItems.length,
            backgroundDecoration: BoxDecoration(color: Colors.transparent),
            pageController: widget.pageController,
            scrollDirection: widget.scrollDirection,
            scaleStateChangedCallback: (state) {
              setState(() {
                scaleState = state;
              });
            },
          ),
          // child: PhotoView(
          //   backgroundDecoration: BoxDecoration(color: Colors.transparent),
          //   imageProvider: CachedNetworkImageProvider(
          //     widget.galleryItems[currentIndex]
          //   ),
          //   heroAttributes: PhotoViewHeroAttributes(tag: (widget.tag ~/ 10) * 10 + currentIndex),
          //   minScale: PhotoViewComputedScale.contained,
          //   scaleStateChangedCallback: (state) {
          //     setState(() {
          //       scaleState = state;
          //     });
          //   },
          // ),
        ),
      ),
    );
  }

  void onTapPhotoView() {
    setState(() {
      barsOpacity = (barsOpacity <= 0.0) ? 1.0 : 0.0;
    });
  }

  void onVerticalDragStart(DragStartDetails details) {
    if (isHorizontalScrolling) return;
    setState(() {
      barsOpacity = 0.0;
      photoViewAnimationDurationMilliSec = 0;
    });
    beginningDragPosition = details.globalPosition;
  }

  void onVerticalDragUpdate(DragUpdateDetails details) {
    if (isHorizontalScrolling) return;
    setState(() {
      barsOpacity = (currentDragPosition.distance < 20.0) ? 1.0 : 0.0;
      currentDragPosition = Offset(
        details.globalPosition.dx - beginningDragPosition.dx,
        details.globalPosition.dy - beginningDragPosition.dy,
      );
    });
  }

  void onVerticalDragEnd(DragEndDetails details) {
    if (isHorizontalScrolling) return;
    if (currentDragPosition.distance < 100.0) {
      setState(() {
        photoViewAnimationDurationMilliSec = 200;
        currentDragPosition = Offset.zero;
        barsOpacity = 1.0;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    final String url = widget.galleryItems[index];
    return PhotoViewGalleryPageOptions(
      imageProvider: CachedNetworkImageProvider(
        url,
      ),
      initialScale: PhotoViewComputedScale.contained,
      // minScale: PhotoViewComputedScale.contained * (0.5 + index / 10),
      // maxScale: PhotoViewComputedScale.covered * 4.1,
      heroAttributes:
          PhotoViewHeroAttributes(tag: widget.galleryItems[index]),
    );
  }
}

class FadeInRoute extends PageRouteBuilder {
  FadeInRoute({
    @required this.widget,
    this.opaque = true,
    this.onTransitionCompleted,
    this.onTransitionDismissed,
  }) : super(
          opaque: opaque,
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            animation.addStatusListener((status) {
              if (status == AnimationStatus.completed &&
                  onTransitionCompleted != null) {
                onTransitionCompleted();
              } else if (status == AnimationStatus.dismissed &&
                  onTransitionDismissed != null) {
                onTransitionDismissed();
              }
            });

            return widget;
          },
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );

  final Widget widget;
  final bool opaque;
  final Function onTransitionCompleted;
  final Function onTransitionDismissed;
}
