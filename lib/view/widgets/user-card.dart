import '../../../model/user.dart';
import 'package:flutter/material.dart';

class UserCard extends StatelessWidget {

  final AuthUser user;
  final bool isFriend;

  UserCard({required this.user, required this.isFriend});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            child: CircleAvatar(
              child: ClipOval(
                child: Stack(
                  children: <Widget>[
                    user.getImageWidget(),
                  ],
                ),
              ),
              radius: 28,
              // backgroundImage: NetworkImage('https://via.placeholder.com/300'),
              backgroundColor: Colors.transparent,
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 8),
              child: Column(
                children: [
                  //---------------------------------
                  //  name and tag
                  //---------------------------------
                  Row(
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                            color: Theme.of(context).textTheme.bodyText1?.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 15),
                      ),
                      isFriend ? Container(
                        margin: EdgeInsets.only(left: 8),
                        height: 21,
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).colorScheme.secondary,),
                        alignment: Alignment.center,
                        child: Text(
                          'フレンド',
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w400,
                              fontSize: 11),
                        ),
                      ) : Container(
                        width: 0,
                        height: 0,
                      )
                    ],
                  ),
                  //---------------------------------
                  //  custom id
                  //---------------------------------
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '@' + user.customId,
                      style: TextStyle(
                          color: Theme.of(context).textTheme.subtitle1?.color,
                          fontWeight: FontWeight.w400,
                          fontSize: 15),
                    ),
                  ),
                  //---------------------------------
                  //  bio
                  //---------------------------------
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      user.bio,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyText1?.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
