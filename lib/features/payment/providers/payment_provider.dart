import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_cache.dart';

enum PaymentType { upi, card, cod }

class PaymentMethod {
  final String id;
  final PaymentType type;
  final String title;
  final String subtitle;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.isDefault,
  });

  PaymentMethod copyWith({
    String? id,
    PaymentType? type,
    String? title,
    String? subtitle,
    bool? isDefault,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'isDefault': isDefault,
    };
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      type: PaymentType.values.firstWhere((e) => e.name == json['type']),
      title: json['title'],
      subtitle: json['subtitle'],
      isDefault: json['isDefault'] ?? false,
    );
  }
}

class PaymentState {
  final List<PaymentMethod> methods;
  final bool isLoading;

  const PaymentState({
    this.methods = const [],
    this.isLoading = false,
  });

  PaymentState copyWith({
    List<PaymentMethod>? methods,
    bool? isLoading,
  }) {
    return PaymentState(
      methods: methods ?? this.methods,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  static const String _keyPaymentMethods = 'key_payment_methods';

  PaymentNotifier() : super(const PaymentState()) {
    _loadMethods();
  }

  void _loadMethods() {
    try {
      final jsonString = LocalCache.getString(_keyPaymentMethods);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decodedList = json.decode(jsonString);
        final list = decodedList.map((e) => PaymentMethod.fromJson(e)).toList();
        state = state.copyWith(methods: list);
      } else {
        // Pre-populate defaults
        final defaults = [
          const PaymentMethod(
            id: 'cod_default',
            type: PaymentType.cod,
            title: 'Cash on Delivery',
            subtitle: 'Pay with cash/UPI upon delivery',
            isDefault: true,
          ),
          const PaymentMethod(
            id: 'upi_gpay',
            type: PaymentType.upi,
            title: 'Google Pay',
            subtitle: 'foodyshop@okaxis',
            isDefault: false,
          ),
        ];
        state = state.copyWith(methods: defaults);
        _saveToCache(defaults);
      }
    } catch (_) {
      // Fallback
    }
  }

  void _saveToCache(List<PaymentMethod> list) {
    try {
      final listJson = list.map((e) => e.toJson()).toList();
      LocalCache.setString(_keyPaymentMethods, json.encode(listJson));
    } catch (_) {
      // Fallback
    }
  }

  void addPaymentMethod({
    required String id,
    required PaymentType type,
    required String title,
    required String subtitle,
  }) {
    final newMethod = PaymentMethod(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      isDefault: false,
    );

    final list = List<PaymentMethod>.from(state.methods)..add(newMethod);
    state = state.copyWith(methods: list);
    _saveToCache(list);
  }

  void deletePaymentMethod(String id) {
    // COD cannot be deleted as it is a default fallback
    if (id == 'cod_default') return;

    final list = List<PaymentMethod>.from(state.methods)
      ..removeWhere((e) => e.id == id);
      
    // If deleted method was default, set COD as default
    bool wasDefault = state.methods.firstWhere((e) => e.id == id).isDefault;
    if (wasDefault) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].id == 'cod_default') {
          list[i] = list[i].copyWith(isDefault: true);
        }
      }
    }

    state = state.copyWith(methods: list);
    _saveToCache(list);
  }

  void setDefaultMethod(String id) {
    final list = state.methods.map((method) {
      return method.copyWith(isDefault: method.id == id);
    }).toList();

    state = state.copyWith(methods: list);
    _saveToCache(list);
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier();
});
