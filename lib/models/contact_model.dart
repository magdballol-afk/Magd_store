class ContactModel {
  final int? id;
  final String name;
  final String phone;
  final double balanceSyr; // الرصيد المترتب بالليرة السورية
  final double balanceUsd; // الرصيد المترتب بالدولار

  ContactModel({
    this.id,
    required this.name,
    this.phone = '',
    this.balanceSyr = 0.0,
    this.balanceUsd = 0.0,
  });

  // خاصية مرادفة لدعم التوافق مع الكود القديم الذي يقرأ balance مباشرة
  double get balance => balanceSyr;

  // دعم fromJson و fromMap
  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      balanceSyr: (json['balance_syr'] as num?)?.toDouble() ??
          (json['balance'] as num?)?.toDouble() ??
          0.0,
      balanceUsd: (json['balance_usd'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory ContactModel.fromMap(Map<String, dynamic> map) =>
      ContactModel.fromJson(map);

  // دعم toJson و toMap
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'balance_syr': balanceSyr,
      'balance_usd': balanceUsd,
      'balance': balanceSyr,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  ContactModel copyWith({
    int? id,
    String? name,
    String? phone,
    double? balanceSyr,
    double? balanceUsd,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      balanceSyr: balanceSyr ?? this.balanceSyr,
      balanceUsd: balanceUsd ?? this.balanceUsd,
    );
  }
}

// إضافة اسم مرادف لضمان عمل Type 'Contact' في new_invoice_screen.dart
typedef Contact = ContactModel;
