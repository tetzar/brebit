import 'package:flutter/material.dart';

import '../../../../../model/post.dart';
import 'custom.dart';

class PostBody extends StatelessWidget {
  final Post post;

  PostBody({@required this.post});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> body = post.getBody();
    Widget bodyWidget;
    switch (body['type']) {
      case 'custom':
        bodyWidget = CustomBody(body: body, imageUrls: post.getImageUrls());
        break;
      default:
        bodyWidget = Container(
          child: Text('unknown type post : ' + body['type']),
        );
    }
    return Container(
      width: double.infinity,
      child: bodyWidget,
    );
  }
}
