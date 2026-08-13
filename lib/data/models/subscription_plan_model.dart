import 'package:equatable/equatable.dart';

/// An immutable, typed representation of an offered subscription plan.
///
/// Replaces the raw `Map<String, dynamic>` previously consumed by the
/// presentation layer via `_stringOf(plan, 'name')` and `_priceOf(plan)`.
class SubscriptionPlanModel extends Equatable {
  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.description,
    this.price = 0,
    this.currency = 'USD',
    this.features = const <String>[],
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    final price = json['price'];
    final features = json['features'];
    return SubscriptionPlanModel(
      id: _asString(json['id']),
      name: _asString(json['name']),
      description: _asString(json['description']),
      price: price is num ? price.toDouble() : 0,
      currency: _asStringOr(json['currency'], 'USD'),
      features: features is List
          ? features.whereType<String>().toList()
          : const <String>[],
    );
  }

  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final List<String> features;

  SubscriptionPlanModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? currency,
    List<String>? features,
  }) => SubscriptionPlanModel(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    price: price ?? this.price,
    currency: currency ?? this.currency,
    features: features ?? this.features,
  );

  @override
  List<Object?> get props => [id, name, description, price, currency, features];
}

String _asString(Object? value) => value is String ? value : '';
String _asStringOr(Object? value, String fallback) =>
    value is String ? value : fallback;
