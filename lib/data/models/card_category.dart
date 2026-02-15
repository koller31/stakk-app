import 'wallet_card_model.dart';

/// Categories for organizing wallet cards
enum CardCategory {
  idCards,
  memberships,
  insurance,
  giftCards,
  trafficDocuments,
  other,
}

/// Metadata and utilities for card categories
class CardCategoryMetadata {
  static const Map<CardCategory, String> displayNames = {
    CardCategory.idCards: 'ID Cards',
    CardCategory.memberships: 'Memberships',
    CardCategory.insurance: 'Insurance',
    CardCategory.giftCards: 'Gift Cards',
    CardCategory.trafficDocuments: 'Traffic Documents',
    CardCategory.other: 'Other',
  };

  static const Map<CardCategory, String> icons = {
    CardCategory.idCards: '🪪',
    CardCategory.memberships: '🎫',
    CardCategory.insurance: '🛡️',
    CardCategory.giftCards: '🎁',
    CardCategory.trafficDocuments: '🚗',
    CardCategory.other: '📋',
  };

  static const Map<CardCategory, int> defaultOrder = {
    CardCategory.idCards: 0,
    CardCategory.memberships: 1,
    CardCategory.insurance: 2,
    CardCategory.giftCards: 3,
    CardCategory.trafficDocuments: 4,
    CardCategory.other: 5,
  };

  static String getDisplayName(CardCategory category) {
    return displayNames[category] ?? 'Unknown';
  }

  static String getIcon(CardCategory category) {
    return icons[category] ?? '📋';
  }

  static int getDefaultOrder(CardCategory category) {
    return defaultOrder[category] ?? 999;
  }

  static CardCategory getCategoryForCardType(CardType cardType) {
    switch (cardType) {
      case CardType.id:
      case CardType.driversLicense:
        return CardCategory.idCards;
      case CardType.membership:
        return CardCategory.memberships;
      case CardType.insurance:
      case CardType.healthInsurance:
        return CardCategory.insurance;
      case CardType.giftCard:
        return CardCategory.giftCards;
      case CardType.vehicleRegistration:
        return CardCategory.trafficDocuments;
      case CardType.other:
        return CardCategory.other;
    }
  }

  static int fromCategory(CardCategory category) {
    switch (category) {
      case CardCategory.idCards:
        return 0;
      case CardCategory.memberships:
        return 1;
      case CardCategory.insurance:
        return 2;
      case CardCategory.giftCards:
        return 3;
      case CardCategory.trafficDocuments:
        return 4;
      case CardCategory.other:
        return 5;
    }
  }
}

/// Per-category user preferences (persisted via SharedPreferences as JSON)
class CategoryPreferences {
  final CardCategory category;
  final int order;
  final bool isVisible;
  final String? customName;

  CategoryPreferences({
    required this.category,
    required this.order,
    this.isVisible = true,
    this.customName,
  });

  factory CategoryPreferences.defaultFor(CardCategory category) {
    return CategoryPreferences(
      category: category,
      order: CardCategoryMetadata.getDefaultOrder(category),
    );
  }

  factory CategoryPreferences.fromJson(Map<String, dynamic> json) {
    return CategoryPreferences(
      category: CardCategory.values.firstWhere(
        (c) => c.toString() == json['category'],
        orElse: () => CardCategory.other,
      ),
      order: json['order'] ?? 999,
      isVisible: json['isVisible'] ?? true,
      customName: json['customName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category.toString(),
      'order': order,
      'isVisible': isVisible,
      'customName': customName,
    };
  }

  CategoryPreferences copyWith({
    int? order,
    bool? isVisible,
    String? customName,
  }) {
    return CategoryPreferences(
      category: category,
      order: order ?? this.order,
      isVisible: isVisible ?? this.isVisible,
      customName: customName ?? this.customName,
    );
  }
}
