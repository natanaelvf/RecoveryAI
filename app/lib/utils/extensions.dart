import 'package:intl/intl.dart';

/// Number formatting extensions.
extension NumFormatting on num {
  /// Format as currency (€1,400)
  String toEuroCurrency() {
    final fmt = NumberFormat.currency(locale: 'fi_FI', symbol: '€', decimalDigits: 0);
    return fmt.format(this);
  }

  /// Format with Finnish locale (1 400)
  String toFinnish() {
    final fmt = NumberFormat('#,###', 'fi_FI');
    return fmt.format(this);
  }
}

/// String convenience extensions.
extension StringUtils on String {
  /// Capitalize first letter.
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
