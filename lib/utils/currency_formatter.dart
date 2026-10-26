// All money is shown in Indian Rupees (₹).

String _groupIndianDigits(String digits) {
  if (digits.length <= 3) return digits;
  final lastThree = digits.substring(digits.length - 3);
  var leading = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (leading.length > 2) {
    groups.insert(0, leading.substring(leading.length - 2));
    leading = leading.substring(0, leading.length - 2);
  }
  if (leading.isNotEmpty) groups.insert(0, leading);
  return '${groups.join(',')},$lastThree';
}

String _formatAmount(double amount, {required bool decimals}) {
  if (!amount.isFinite) return '₹0.00';
  final safeAmount = amount < 0 ? 0.0 : amount;
  final fixed = safeAmount.toStringAsFixed(decimals ? 2 : 0);
  final parts = fixed.split('.');
  final grouped = _groupIndianDigits(parts[0]);
  return decimals ? '₹$grouped.${parts[1]}' : '₹$grouped';
}

// Full amount with two decimals, e.g. ₹1,25,000.00.
String formatRupees(double amount) => _formatAmount(amount, decimals: true);

// Short price for cards, e.g. ₹40 or ₹1,25,000.
String formatPrice(double amount) {
  if (amount == amount.roundToDouble() && amount.isFinite) {
    return _formatAmount(amount, decimals: false);
  }
  return _formatAmount(amount, decimals: true);
}
