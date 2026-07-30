class Subscription {
  final String id;
  final String planId;
  final String userId;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final double price;
  final String currency;
  final int billingCycleDays;
  final bool autoRenew;
  final int? usedMessages;
  final int? usedFileSize;

  Subscription({
    required this.id,
    required this.planId,
    required this.userId,
    required this.plan,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.price,
    required this.currency,
    this.billingCycleDays = 30,
    this.autoRenew = true,
    this.usedMessages = 0,
    this.usedFileSize = 0,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      planId: json['planId'] as String,
      userId: json['userId'] as String,
      plan: SubscriptionPlan.fromJson(json['plan'] as Map<String, dynamic>),
      status: SubscriptionStatus.values.byName(json['status'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      billingCycleDays: json['billingCycleDays'] as int? ?? 30,
      autoRenew: json['autoRenew'] as bool? ?? true,
      usedMessages: json['usedMessages'] as int? ?? 0,
      usedFileSize: json['usedFileSize'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'planId': planId,
    'userId': userId,
    'plan': plan.toJson(),
    'status': status.name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'price': price,
    'currency': currency,
    'billingCycleDays': billingCycleDays,
    'autoRenew': autoRenew,
    'usedMessages': usedMessages,
    'usedFileSize': usedFileSize,
  };

  bool get isActive => status == SubscriptionStatus.active;
  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());
}

enum SubscriptionStatus {
  active,
  canceled,
  expired,
  pending,
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final int billingCycleDays;
  final int messagesPerDay;
  final int maxFileSize;
  final List<String> availableModels;
  final List<String> features;
  final bool isPremium;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    this.billingCycleDays = 30,
    required this.messagesPerDay,
    required this.maxFileSize,
    required this.availableModels,
    required this.features,
    this.isPremium = false,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      billingCycleDays: json['billingCycleDays'] as int? ?? 30,
      messagesPerDay: json['messagesPerDay'] as int,
      maxFileSize: json['maxFileSize'] as int,
      availableModels: List<String>.from(json['availableModels'] as List? ?? []),
      features: List<String>.from(json['features'] as List? ?? []),
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'currency': currency,
    'billingCycleDays': billingCycleDays,
    'messagesPerDay': messagesPerDay,
    'maxFileSize': maxFileSize,
    'availableModels': availableModels,
    'features': features,
    'isPremium': isPremium,
  };
}
