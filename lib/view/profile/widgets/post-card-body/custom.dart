import 'dart:typed_data';

import 'package:brebit/utils/aws.dart';
import 'package:brebit/view/timeline/widget/photo-viewer.dart';
import 'package:flutter/material.dart';

import '../../../../../route/route.dart';
import '../../../timeline/widget/log-card.dart';

class CustomBody extends StatelessWidget {
  final Map<String, dynamic> body;
  final List<S3Image> images;

  CustomBody({required this.body, required this.images});

  @override
  Widget build(BuildContext context) {
    List<Widget> children = <Widget>[];
    if (body.containsKey('content')) {
      children.add(Text(
        body['content'],
        textAlign: TextAlign.left,
        style: Theme.of(context)
            .textTheme
            .bodyText1
            ?.copyWith(fontSize: 15, fontWeight: FontWeight.w400),
      ));
    }

    if (body.containsKey('habit_log')) {
      children.add(Container(
        margin: EdgeInsets.only(top: 4),
        child: LogCard(
          log: body['habit_log'],
        ),
      ));
    }
    if (images.length > 0) {
      children.add(
        ImageGrid(images: images),
      );
    }
    return Container(
        width: double.infinity,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children));
  }
}

class ImageGrid extends StatefulWidget {
  final List<S3Image> images;

  ImageGrid({required this.images});

  @override
  _ImageGridState createState() => _ImageGridState();
}

class _ImageGridState extends State<ImageGrid> {
  late List<S3Image> images;

  @override
  void initState() {
    images = widget.images;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ImageGrid oldWidget) {
    images = widget.images;
    super.didUpdateWidget(oldWidget);
  }

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
    switch (images.length) {
      case 1:
        return getTile(images[0],
            roundTopRight: true,
            roundTopLeft: true,
            roundBottomLeft: true,
            roundBottomRight: true);
      case 2:
        return Row(
          children: [
            Expanded(
              child: Container(
                height: double.infinity,
                padding: EdgeInsets.only(right: 2),
                child: getTile(images[0],
                    roundBottomLeft: true, roundTopLeft: true),
              ),
            ),
            Expanded(
              child: Container(
                height: double.infinity,
                padding: EdgeInsets.only(left: 2),
                child: getTile(images[1],
                    roundTopRight: true, roundBottomRight: true),
              ),
            )
          ],
        );
      case 3:
        return Row(
          children: [
            Expanded(
              child: Container(
                height: double.infinity,
                padding: EdgeInsets.only(right: 2),
                child: getTile(images[0],
                    roundTopLeft: true, roundBottomLeft: true),
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
                      child: getTile(images[1], roundTopRight: true),
                    ),
                    Container(
                      padding: EdgeInsets.only(top: 2),
                      height: 80,
                      width: double.infinity,
                      child: getTile(images[2], roundBottomRight: true),
                    ),
                  ],
                ),
              ),
            )
          ],
        );
      default:
        return Column(
          children: [
            Expanded(
              child: Container(
                height: 80,
                padding: EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Expanded(
                        child: Container(
                      padding: EdgeInsets.only(right: 2),
                      height: double.infinity,
                      width: double.infinity,
                      child: getTile(images[0], roundTopLeft: true),
                    )),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(left: 2),
                        height: double.infinity,
                        width: double.infinity,
                        child: getTile(images[1], roundTopRight: true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 80,
                padding: EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(right: 2),
                        height: double.infinity,
                        width: double.infinity,
                        child: getTile(images[2], roundBottomLeft: true),
                      ),
                    ),
                    Expanded(
                        child: Container(
                      padding: EdgeInsets.only(left: 2),
                      height: 80,
                      width: double.infinity,
                      child: getTile(images[3], roundBottomRight: true),
                    )),
                  ],
                ),
              ),
            )
          ],
        );
    }
  }

  Widget getTile(
    S3Image image, {
    bool roundTopRight = false,
    bool roundTopLeft = false,
    bool roundBottomLeft = false,
    bool roundBottomRight = false,
  }) {
    return GestureDetector(
      onTap: () {
        open(context, image);
      },
      child: FutureBuilder(
        future: image.getImage(),
        builder: (context, snapshot) {
          Widget child = (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData)
              ? Hero(
                  tag: image.url,
                  child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomRight:
                              Radius.circular(roundBottomRight ? 8 : 0),
                          bottomLeft: Radius.circular(roundBottomLeft ? 8 : 0),
                          topRight: Radius.circular(roundTopRight ? 8 : 0),
                          topLeft: Radius.circular(roundTopLeft ? 8 : 0),
                        ),
                        image: DecorationImage(
                            image: MemoryImage(snapshot.data as Uint8List),
                            fit: BoxFit.cover),
                      )),
                )
              : Hero(
                  tag: image.url,
                  child: Container(
                    color: Theme.of(context).backgroundColor,
                  ));
          return AnimatedSwitcher(
            duration: Duration(milliseconds: 500),
            child: child,
          );
        },
      ),
    );
  }

  void open(BuildContext ctx, S3Image image) {
    ApplicationRoutes.push(FadeInRoute(
      widget: GalleryPhotoViewWrapper(
        images: images,
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        tag: image.url,
        scrollDirection: Axis.horizontal,
      ),
      opaque: false,
    ));
  }
}
