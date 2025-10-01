class PhoneUtils {
  static String normalizePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return phoneNumber;
    
    // Извлекаем только цифры из номера
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Если номер начинается с 996, добавляем +
    if (digitsOnly.startsWith('996')) {
      return '+$digitsOnly';
    }
    
    // Если номер начинается с 9 (без 996), добавляем +996
    if (digitsOnly.startsWith('9') && digitsOnly.length == 9) {
      return '+996$digitsOnly';
    }
    
    // Если номер уже содержит 996 в начале, просто добавляем +
    if (digitsOnly.length >= 12 && digitsOnly.startsWith('996')) {
      return '+$digitsOnly';
    }
    
    // Если номер уже содержит +, возвращаем как есть
    if (phoneNumber.startsWith('+')) {
      return phoneNumber;
    }
    
    return phoneNumber;
  }
  
  static String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return phoneNumber;
    
    String normalized = normalizePhoneNumber(phoneNumber);
    
    if (normalized.startsWith('+996') && normalized.length == 13) {
      String digits = normalized.substring(4);
      return '+996 ${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 9)}';
    }
    
    return normalized;
  }
}
