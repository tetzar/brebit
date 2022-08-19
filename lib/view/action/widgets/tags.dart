
import 'package:flutter/material.dart';

class Tags extends StatelessWidget {

  final List<TagCard> tags;
  Tags({required this.tags});

  @override
  Widget build(BuildContext context) {
    return tags.length > 0
        ? Container(
      margin: EdgeInsets.only(top: 16),
      alignment: Alignment.topLeft,
      child: Wrap(
          direction: Axis.horizontal,
          crossAxisAlignment: WrapCrossAlignment.start,
          alignment: WrapAlignment.start,
          runSpacing: 8,
          spacing: 8,
          clipBehavior: Clip.antiAlias,
          children: tags),
    )
        : Container(
      height: 0,
    );
  }
}

class SimpleTagCard extends TagCard {

  final Function? onCancel;
  final String name;

  SimpleTagCard({this.onCancel, required this.name});

  @override
  Widget getChild() {
    Function? onCancel = this.onCancel;
    if (onCancel == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(
              right: 18
            ),
            child: Text(
              name,
              style: TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          // margin: EdgeInsets.only(ri),
          child: Text(
            name,
            style: TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
          ),
        ),
        IconButton(
          padding: EdgeInsets.all(0),
          icon: Icon(
            Icons.close,
            size: 15,
          ),
          onPressed: () {
            onCancel();
          },
        )
      ],
    );
  }
}

class AddTagCard extends TagCard {

  final void Function() onTap;
  AddTagCard({required this.onTap});

  @override
  Widget getChild() {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add,
            size: 15,
          ),
          Container(
            margin: EdgeInsets.only(
              left: 10,
              right: 16
            ),
            child: Text(
              '追加',
              style: TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
            ),
          )
        ],
      ),
    );
  }
}

abstract class TagCard extends StatelessWidget {

  Widget getChild() {
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(left: 18),
        height: 32,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            color: Theme.of(context).primaryColorLight),
        child: getChild()
    );
  }
}
