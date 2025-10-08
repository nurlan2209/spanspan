class Validators {
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) return 'Введите номер телефона';
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
      return 'Неверный формат номера';
    }
    return null;
  }

  static String? iin(String? value) {
    if (value == null || value.isEmpty) return 'Введите ИИН';
    if (value.length != 12 || !RegExp(r'^[0-9]{12}$').hasMatch(value)) {
      return 'ИИН должен содержать 12 цифр';
    }
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.isEmpty) return 'Введите $fieldName';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Введите пароль';
    if (value.length < 6) return 'Минимум 6 символов';
    return null;
  }
}
