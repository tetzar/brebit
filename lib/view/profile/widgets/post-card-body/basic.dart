
import '../../../../../model/post.dart';
import 'package:flutter/material.dart';

import 'custom.dart';
class PostBody extends StatelessWidget {
  final Post post;
  final int num;
  PostBody({@required this.post, @required this.num});
  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> body = post.getBody();
    Widget bodyWidget;
    switch (body['type']) {
      case 'custom':
        bodyWidget = CustomBody(body: body, imageUrls: post.getImageUrls(), num: num,);
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
