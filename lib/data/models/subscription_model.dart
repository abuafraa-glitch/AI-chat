import 'package:equatable/equatable.dart';

/// Represents the type of a subscription plan.
enum SubscriptionPlanType {
  free,
  pro,
  enterprise,
  lifetime,
  family,
  team,
  organization,
  custom,
}

/// Represents the billing cycle of a subscription.
enum SubscriptionBillingCycle {
  monthly,
  yearly,
  trial,
  oneTime,
  custom,
}

/// Represents the current status of a user's subscription.
enum SubscriptionStatus {
  active,
  canceled,
  expired,
  pending,
  trialing,
  paused,
}

/// A production-ready, immutable model representing a user's subscription.
///
/// This model is designed to be highly extensible to support various plan types,
/// billing cycles, and future subscription features.
class SubscriptionModel extends Equatable {
  final String id;
  final String userId;
  final SubscriptionPlanType planType;
  final SubscriptionBillingCycle billingCycle;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final double price;
  final String currency;
  final Map<String, dynamic> features;
  final Map<String, dynamic> metadata;

  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.planType,
    required this.billingCycle,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.price,
    required this.currency,
    this.features = const {},
    this.metadata = const {},
  });

  /// Creates a copy of this [SubscriptionModel] with the given fields replaced by the new values.
  SubscriptionModel copyWith({
    String? id,
    String? userId,
    SubscriptionPlanType? planType,
    SubscriptionBillingCycle? billingCycle,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? price,
    String? currency,
    Map<String, dynamic>? features,
    Map<String, dynamic>? metadata,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planType: planType ?? this.planType,
      billingCycle: billingCycle ?? this.billingCycle,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      features: features ?? this.features,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Creates a [SubscriptionModel] instance from a JSON map.
  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json["id"] as String,
      userId: json["userId"] as String,
      planType: SubscriptionPlanType.values.firstWhere(
        (e) => e.name == json["planType"],
        orElse: () => SubscriptionPlanType.custom,
      ),
      billingCycle: SubscriptionBillingCycle.values.firstWhere(
        (e) => e.name == json["billingCycle"],
        orElse: () => SubscriptionBillingCycle.custom,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == json["status"],
        orElse: () => SubscriptionStatus.pending,
      ),
      startDate: DateTime.parse(json["startDate"] as String),
      endDate: json["endDate"] != null ? DateTime.parse(json["endDate"] as String) : null,
      price: (json["price"] as num).toDouble(),
      currency: json["currency"] as String,
      features: json["features"] as Map<String, dynamic>? ?? {},
      metadata: json["metadata"] as Map<String, dynamic>? ?? {},
    );
  }

  /// Converts this [SubscriptionModel] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userId": userId,
      "planType": planType.name,
      "billingCycle": billingCycle.name,
      "status": status.name,
      "startDate": startDate.toIso8601String(),
      "endDate": endDate?.toIso8601String(),
      "price": price,
      "currency": currency,
      "features": features,
      "metadata": metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        planType,
        billingCycle,
        status,
        startDate,
        endDate,
        price,
        currency,
        features,
        metadata,
      ];
}
