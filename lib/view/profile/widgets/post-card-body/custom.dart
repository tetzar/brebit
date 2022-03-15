import 'package:brebit/view/timeline/widget/photo-viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../route/route.dart';
import '../../../timeline/widget/log-card.dart';

class CustomBody extends StatelessWidget {
  final Map<String, dynamic> body;
  final List<String> imageUrls;

  CustomBody({@required this.body, this.imageUrls});

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
            .copyWith(fontSize: 15, fontWeight: FontWeight.w400),
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
    if (imageUrls.length > 0) {
      children.add(
        ImageGrid(imageUrls: imageUrls),
      );
    }
    return Container(
        width: double.infinity,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children));
  }
}

class ImageGrid extends StatefulWidget {
  final List<String> imageUrls;

  ImageGrid({@required this.imageUrls});

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
        return getTile(widget.imageUrls[0],
            roundTopRight: true,
            roundTopLeft: true,
            roundBottomLeft: true,
            roundBottomRight: true);
        break;
      case 2:
        return Row(
          children: [
            Expanded(
              child: Container(
                height: double.infinity,
                padding: EdgeInsets.only(right: 2),
                child: getTile(widget.imageUrls[0],
                    roundBottomLeft: true, roundTopLeft: true),
              ),
            ),
            Expanded(
              child: Container(
                height: double.infinity,
                padding: EdgeInsets.only(left: 2),
                child: getTile(widget.imageUrls[1],
                    roundTopRight: true, roundBottomRight: true),
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
                child: getTile(widget.imageUrls[0],
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
                      child: getTile(widget.imageUrls[1], roundTopRight: true),
                    ),
                    Container(
                      padding: EdgeInsets.only(top: 2),
                      height: 80,
                      width: double.infinity,
                      child:
                          getTile(widget.imageUrls[2], roundBottomRight: true),
                    ),
                  ],
                ),
              ),
            )
          ],
        );
        break;
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
                      child: getTile(widget.imageUrls[0], roundTopLeft: true),
                    )),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(left: 2),
                        height: double.infinity,
                        width: double.infinity,
                        child:
                            getTile(widget.imageUrls[1], roundTopRight: true),
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
                        child:
                            getTile(widget.imageUrls[2], roundBottomLeft: true),
                      ),
                    ),
                    Expanded(
                        child: Container(
                      padding: EdgeInsets.only(left: 2),
                      height: 80,
                      width: double.infinity,
                      child:
                          getTile(widget.imageUrls[3], roundBottomRight: true),
                    )),
                  ],
                ),
              ),
            )
          ],
        );
        break;
    }
  }

  Widget getTile(
    String imageUrl, {
    bool roundTopRight = false,
    bool roundTopLeft = false,
    bool roundBottomLeft = false,
    bool roundBottomRight = false,
  }) {
    return GestureDetector(
      onTap: () {
        open(context, imageUrl);
      },
      child: Hero(
        tag: imageUrl,
        child: CachedNetworkImage(
          fit: BoxFit.cover,
          imageUrl: imageUrl,
          placeholder: (context, url) => Container(
            color: Theme.of(context).backgroundColor,
          ),
          imageBuilder: (BuildContext context, ImageProvider imageProvider) {
            return Container(
                width: double.infinity,
                height: 78,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(roundBottomRight ? 8 : 0),
                    bottomLeft: Radius.circular(roundBottomLeft ? 8 : 0),
                    topRight: Radius.circular(roundTopRight ? 8 : 0),
                    topLeft: Radius.circular(roundTopLeft ? 8 : 0),
                  ),
                  image:
                      DecorationImage(image: imageProvider, fit: BoxFit.cover),
                ));
          },
        ),
      ),
    );
  }

  void open(BuildContext ctx, String tag) {
    ApplicationRoutes.materialKey.currentState.push(FadeInRoute(
      widget: GalleryPhotoViewWrapper(
        galleryItems: this.widget.imageUrls,
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        tag: tag,
        scrollDirection: Axis.horizontal,
      ),
      opaque: false,
    ));
  }
}
