
// ignore: non_constant_identifier_names
import 'dart:ui';

import 'package:brebit/model/strategy.dart';

import 'category_parameter.dart';
import 'habit.dart';
import 'information.dart';
import 'model.dart';

List<Category> categoryFromJson(List<dynamic> decodedList) =>
    new List<Category>.from(
        decodedList.cast<Map<String, dynamic>>().map((x) => Category.fromJson(x)));

List<Map> categoryToJson(List<Category> data) =>
    List<Map>.from(data.map((x) => x.toJson()));

enum CategoryName {
  cigarette,
  alcohol,
  sweets,
  sns,
  notCategorized,
}

final Map<CategoryName, String> categoryNameToSystemName = {
  CategoryName.cigarette: 'cigarette',
  CategoryName.alcohol: 'alcohol',
  CategoryName.sns: 'sns',
  CategoryName.sweets: 'sweet'
};

class Category extends Model {
  static List<Category> categoryList = <Category>[
    Category(
      systemName: 'cigarette',
    )..name = CategoryName.cigarette,
    Category(systemName: 'sweets')..name = CategoryName.sweets,
    Category(systemName: 'alcohol')..name = CategoryName.alcohol,
    Category(systemName: 'sns')..name = CategoryName.sns,
  ];

  set name(CategoryName value) {
    _name = value;
  }

  CategoryName get name {
    return _name ?? CategoryName.notCategorized;
  }

  CategoryName? _name;
  String? categoryName;
  String? briefExpression;
  int? id;
  String systemName;
  Map<int, Habit>? habits;
  Image? img;
  Map<int, Strategy>? strategies;
  Information? information;
  Map<int, CategoryParameter>? params;

  Category({
    this.categoryName,
    this.briefExpression,
    required this.systemName,
    this.id,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    Category? category = Category.findWhereNameIs(json['system_name']);
    Category newCategory = new Category(
      id: json["id"],
      categoryName: json["category_name"],
      briefExpression: json["brief_expression"],
      systemName: json["system_name"],
    );
    int index;
    if (category != null) {
      index = Category.categoryList
          .indexWhere((c) => c.systemName == newCategory.systemName);
      categoryList[index] = newCategory..name = category.name;
    } else {
      Category.categoryList.add(newCategory);
      index = categoryList.length - 1;
    }
    return categoryList[index];
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "category_name": categoryName,
        "brief_expression": briefExpression,
        "system_name": systemName,
      };

  static Category find(int id) {
    List<Category> matches =
        Category.categoryList.where((category) => category.id == id).toList();
    return matches.first;
  }

  static Category findFromCategoryName(CategoryName categoryName) {
    return Category.categoryList
        .firstWhere((category) => category.name == categoryName);
  }

  static Category? findWhereNameIs(String name) {
    try {
      return Category.categoryList
          .firstWhere((category) => category.systemName == name);
    } on StateError {
      return null;
    }
  }

  static List<Category> findAll(List categoryIds) {
    List<Category> categories = <Category>[];
    Category? _category;
    categoryIds.forEach((categoryId) {
      _category = find(categoryId);
      if (_category != null) {
        categories.add(_category!);
      }
    });
    return categories;
  }
}
