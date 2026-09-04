enum ContactType { client, supplier } // عميل أو مورد
enum AccountType { debtor, creditor, balanced } // مدين (عليه فلوس)، دائن (له فلوس)، متزن

class ContactModel {
  final String? id;
  final String name;
  final String phone;
  final String? address;
  final ContactType type; // client أو supplier
  final double balanceSyp; // الرصيد بالليرة السورية
  final double balanceUsd; // الرصيد بالدولار
  final String? notes;
  final DateTime createdAt;

  ContactModel({
    this.id,
    required this.name,
    required this.phone,
    this.address,
    required this.type,
    this.balanceSyp = 0.0,
    this.balanceUsd = 0.0,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // تحويل البيانات إلى Map لحفظها في قاعدة البيانات (SQLite / Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'type': type == ContactType.client ? 'client' : 'supplier',
      'balance_syp': balanceSyp,
      'balance_usd': balanceUsd,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // إنشاء كائن ContactModel من Map قادمة من قاعدة البيانات
  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'],
      type: map['type'] == 'supplier' ? ContactType.supplier : ContactType.client,
      balanceSyp: (map['balance_syp'] as num?)?.toDouble() ?? 0.0,
      balanceUsd: (map['balance_usd'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
    );
  }

  // دالة مساعدة لتحديد حالة الحساب (له / عليه / متزن)
  AccountType get sypAccountStatus {
    if (balanceSyp > 0) return AccountType.creditor; // له
    if (balanceSyp < 0) return AccountType.debtor;   // عليه
    return AccountType.balanced;
  }

  // نسخة معدلة من الكائن (للتحديث السريع)
  ContactModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    ContactType? type,
    double? balanceSyp,
    double? balanceUsd,
    String? notes,
    DateTime? createdAt,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      type: type ?? this.type,
      balanceSyp: balanceSyp ?? this.balanceSyp,
      balanceUsd: balanceUsd ?? this.balanceUsd,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
