import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFDC143C);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF757575);
  static const Color surface = Color(0xFFF7F7F7);
  static const Color border = Color(0xFFE2E2E2);
}

class AppStrings {
  static const String appName = 'ORTUS Martial Arts';
  static const String student = 'Ученик';
  static const String trainer = 'Тренер';
}

class AppData {
  static const List<Map<String, String>> productCategories = [
    {'key': 'tshirt', 'label': 'Футболки'},
    {'key': 'hoodie', 'label': 'Худи'},
    {'key': 'cap', 'label': 'Кепки'},
    {'key': 'accessory', 'label': 'Аксессуары'},
    {'key': 'other', 'label': 'Другое'},
  ];

  static const List<Map<String, String>> orderStatuses = [
    {'key': 'new', 'label': 'Новый'},
    {'key': 'contacted', 'label': 'Связались'},
    {'key': 'paid', 'label': 'Оплачен'},
    {'key': 'delivering', 'label': 'Доставляется'},
    {'key': 'completed', 'label': 'Завершён'},
    {'key': 'canceled', 'label': 'Отменён'},
  ];

  static const List<String> trainingSlots = [
    '08:00-09:30',
    '10:00-11:30',
    '16:00-17:00',
    '18:00-20:00',
    '20:00-22:00',
  ];
}
