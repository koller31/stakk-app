import 'package:hive/hive.dart';
import 'card_category.dart';

part 'wallet_card_model.g.dart';

/// Type of wallet card
enum CardType {
  id,
  driversLicense,
  giftCard,
  membership,
  insurance,
  healthInsurance,
  vehicleRegistration,
  other,
}

/// Display format for viewing the card
enum DisplayFormat {
  card,
  document,
}

@HiveType(typeId: 3)
class WalletCardModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? nickname;

  @HiveField(3)
  final int cardTypeIndex;

  @HiveField(4)
  final String frontImagePath;

  @HiveField(5)
  final String? backImagePath;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8)
  final Map<String, dynamic>? extractedData;

  @HiveField(9)
  final String? notes;

  @HiveField(10)
  final int displayOrder;

  @HiveField(11)
  final int categoryIndex;

  @HiveField(12)
  final int displayFormatIndex;

  @HiveField(13)
  final bool hasBarcode;

  WalletCardModel({
    required this.id,
    required this.name,
    this.nickname,
    required this.cardTypeIndex,
    required this.frontImagePath,
    this.backImagePath,
    required this.createdAt,
    required this.updatedAt,
    this.extractedData,
    this.notes,
    this.displayOrder = 0,
    required this.categoryIndex,
    this.displayFormatIndex = 0,
    bool? hasBarcode,
  }) : hasBarcode = hasBarcode ?? defaultHasBarcodeForType(CardType.values[cardTypeIndex]);

  /// Returns whether a card type typically has a scannable barcode
  static bool defaultHasBarcodeForType(CardType type) {
    switch (type) {
      case CardType.driversLicense:
      case CardType.id:
      case CardType.membership:
      case CardType.giftCard:
      case CardType.insurance:
      case CardType.healthInsurance:
        return true;
      case CardType.vehicleRegistration:
      case CardType.other:
        return false;
    }
  }

  CardType get cardType => CardType.values[cardTypeIndex];
  CardCategory get category => CardCategory.values[categoryIndex];
  DisplayFormat get displayFormat => DisplayFormat.values[displayFormatIndex];

  WalletCardModel copyWith({
    String? id,
    String? name,
    String? nickname,
    int? cardTypeIndex,
    String? frontImagePath,
    String? backImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? extractedData,
    String? notes,
    int? displayOrder,
    int? categoryIndex,
    int? displayFormatIndex,
    bool? hasBarcode,
  }) {
    return WalletCardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      cardTypeIndex: cardTypeIndex ?? this.cardTypeIndex,
      frontImagePath: frontImagePath ?? this.frontImagePath,
      backImagePath: backImagePath ?? this.backImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      extractedData: extractedData ?? this.extractedData,
      notes: notes ?? this.notes,
      displayOrder: displayOrder ?? this.displayOrder,
      categoryIndex: categoryIndex ?? this.categoryIndex,
      displayFormatIndex: displayFormatIndex ?? this.displayFormatIndex,
      hasBarcode: hasBarcode ?? this.hasBarcode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nickname': nickname,
      'cardTypeIndex': cardTypeIndex,
      'frontImagePath': frontImagePath,
      'backImagePath': backImagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'extractedData': extractedData,
      'notes': notes,
      'displayOrder': displayOrder,
      'categoryIndex': categoryIndex,
      'displayFormatIndex': displayFormatIndex,
      'hasBarcode': hasBarcode,
    };
  }

  factory WalletCardModel.fromJson(Map<String, dynamic> json) {
    return WalletCardModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nickname: json['nickname'] as String?,
      cardTypeIndex: json['cardTypeIndex'] as int,
      frontImagePath: json['frontImagePath'] as String,
      backImagePath: json['backImagePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      extractedData: json['extractedData'] as Map<String, dynamic>?,
      notes: json['notes'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      categoryIndex: json['categoryIndex'] as int,
      displayFormatIndex: json['displayFormatIndex'] as int? ?? 0,
      hasBarcode: json['hasBarcode'] as bool?,
    );
  }
}
