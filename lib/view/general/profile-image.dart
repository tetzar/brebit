import 'dart:typed_data';

import 'package:brebit/utils/aws.dart';
import 'package:flutter/material.dart';

class ProfileImageWithS3 extends StatefulWidget {
  final S3Image s3image;

  const ProfileImageWithS3(this.s3image, {Key? key}) : super(key: key);

  @override
  State<ProfileImageWithS3> createState() => _ProfileImageWithS3State();
}

class _ProfileImageWithS3State extends State<ProfileImageWithS3> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.s3image.getImage(),
      builder: (context, snapshot) {
        Widget child = (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData)
            ? Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: MemoryImage(snapshot.data as Uint8List),
                      fit: BoxFit.cover),
                ))
            : Container(
                color: Theme.of(context).backgroundColor,
              );
        return AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
          child: child,
        );
      },
    );
  }
}
