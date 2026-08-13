import 'package:equatable/equatable.dart';

/// An immutable, typed representation of a single payment transaction.
///
/// Replaces the raw `Map<String, dynamic>` previously consumed by the
/// presentation layer via `_stringOf(item, 'status')` and `_amountOf(item)`.
class PaymentModel extends Equatable {
  const PaymentModel({
    required this.id,
    required this.status,
    required this.amount,
    this.currency = 'USD',
    this.description = '',
    this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'];
    final rawDate = json['createdAt'];
    return PaymentModel(
      id: _asString(json['id']),
      status: _asString(json['status']),
      amount: amount is num ? amount.toDouble() : 0,
      currency: _asStringOr(json['currency'], 'USD'),
      description: _asString(json['description']),
      createdAt: rawDate is String ? DateTime.tryParse(rawDate) : null,
    );
  }

  final String id;
  final String status;
  final double amount;
  final String currency;
  final String description;
  final DateTime? createdAt;

  PaymentModel copyWith({
    String? id,
    String? status,
    double? amount,
    String? currency,
    String? description,
    DateTime? createdAt,
  }) => PaymentModel(
    id: id ?? this.id,
    status: status ?? this.status,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    status,
    amount,
    currency,
    description,
    createdAt,
  ];
}

String _asString(Object? value) => value is String ? value : '';
String _asStringOr(Object? value, String fallback) =>
    value is String ? value : fallback;
