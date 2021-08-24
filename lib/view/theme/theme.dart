import 'package:flutter/material.dart';

class BrightThemeData {
  static ThemeData getThemeData(BuildContext context) => ThemeData(
      backgroundColor: Color(0xFFF7F8F9),
      accentColor: Color(0xFF65BDC0),
      primaryColorDark: Color(0xFFDBDBDB),
      primaryColorLight: Color(0xFFEDF7F9),
      primaryColor: Color(0xFFFFFFFF),
      disabledColor: Color(0xFFBEBEBE),
      accentIconTheme: IconThemeData(color: Color(0xFFEE777F), size: 18),
      inputDecorationTheme: InputDecorationTheme(
          contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 16),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(
              width: 1,
              color: Color(0xFFEB5757),
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
          border: OutlineInputBorder(borderSide: BorderSide.none),
          fillColor: Color(0xFFF2F2F2),
          filled: true,
          labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFFBEBEBE),
          ),
          errorStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFFEB5757),
          ),
          counterStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF05182E),
          )),
      textTheme: Theme.of(context)
          .textTheme
          .apply(
            bodyColor: Color(0xFF05182E),
            displayColor: Color(0xFF05182E),
          )
          .copyWith(
        bodyText1: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 13
        ),
            subtitle1: TextStyle(
              color: Color(0xFF6F707E),
              fontWeight: FontWeight.w400,
              fontSize: 13
            ),
          ),
      accentTextTheme: Theme.of(context).accentTextTheme.copyWith(
        subtitle1: TextStyle(
          color: Color(0xFFEE777F),
          fontSize: 13,
          fontWeight: FontWeight.w700
        )
      ),
      shadowColor: Colors.black.withOpacity(0.15),
      errorColor: Color(0xFFEB5757),
      appBarTheme: AppBarTheme(
        color: Color(0xFFffffff),
        shadowColor: Color(0x00ffffff),
        iconTheme:
            IconThemeData(color: Color(0xFF05182e), opacity: 1, size: 32.0),
        actionsIconTheme:
            IconThemeData(color: Color(0xFF05182e), opacity: 1, size: 32.0),
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Color(0xFF05182E),
            ),
      ),
      buttonTheme: ButtonThemeData(
          colorScheme: Theme.of(context)
              .buttonTheme
              .colorScheme
              .copyWith(primary: Color(0xFFFFFFFF))),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xFFFFFFFF),
          unselectedIconTheme:
              IconThemeData(color: Color(0xFF05182E), opacity: 1, size: 32),
          selectedIconTheme:
              IconThemeData(color: Color(0xFF05182E), opacity: 1, size: 32)),
      scaffoldBackgroundColor: Color(0xFFFAFAFA),
  );
}
