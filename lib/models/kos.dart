/// Model data kos yang dipakai pada seluruh layer aplikasi.
class Kos {
  const Kos({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.price,
    required this.description,
    required this.isVerified,
  });

  final String id;
  final String ownerId;
  final String name;
  final String address;
  final int price;
  final String description;
  final bool isVerified;

  bool isOwnedBy(String? userId) => userId != null && userId == ownerId;

  factory Kos.fromMap(Map<String, dynamic> map) {
    return Kos(
      id: map['id'] as String,
      ownerId: (map['owner_id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      address: (map['address'] ?? '') as String,
      price: (map['price'] as num?)?.toInt() ?? 0,
      description: (map['description'] ?? '') as String,
      isVerified: (map['is_verified'] ?? false) as bool,
    );
  }

  /// Format harga sederhana tanpa package tambahan: 750000 -> Rp 750.000.
  String get priceLabel {
    final String digits = price.toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp $buffer / bulan';
  }
}
