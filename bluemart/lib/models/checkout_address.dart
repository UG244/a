class CheckoutAddress {
  final int? id;
  final String label;
  final String fullAddress;
  final String recipient;
  final String phone;
  final bool isDefault;
  final String? userId;

  CheckoutAddress({
    this.id,
    required this.label,
    required this.fullAddress,
    required this.recipient,
    required this.phone,
    this.isDefault = true,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'label': label,
      'fullAddress': fullAddress,
      'recipient': recipient,
      'phone': phone,
      'isDefault': isDefault ? 1 : 0,
      'userId': userId,
    };
  }

  factory CheckoutAddress.fromMap(Map<String, dynamic> map) {
    return CheckoutAddress(
      id: (map['id'] as num?)?.toInt(),
      label: map['label'] as String? ?? '',
      fullAddress: map['fullAddress'] as String? ?? '',
      recipient: map['recipient'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      isDefault: map['isDefault'] == 1 || map['isDefault'] == true || map['isDefault'] == 'true',
      userId: map['userId'] as String?,
    );
  }
}
