import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/logger_service.dart';

class OfferState {
  final bool isLoading;
  final double discount;
  final String? appliedCode;
  final String? errorMessage;
  final double? backendTotal;

  const OfferState({
    this.isLoading = false,
    this.discount = 0.0,
    this.appliedCode,
    this.errorMessage,
    this.backendTotal,
  });

  OfferState copyWith({
    bool? isLoading,
    double? discount,
    String? appliedCode,
    String? errorMessage,
    double? backendTotal,
  }) {
    return OfferState(
      isLoading: isLoading ?? this.isLoading,
      discount: discount ?? this.discount,
      appliedCode: appliedCode ?? this.appliedCode,
      errorMessage: errorMessage ?? this.errorMessage,
      backendTotal: backendTotal ?? this.backendTotal,
    );
  }
}

class OfferNotifier extends StateNotifier<OfferState> {
  OfferNotifier() : super(const OfferState());

  Future<bool> validateOffer({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required String code,
    required double cartTotal,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Toggle this to test live API
    final bool useMock = false;

    // ignore: dead_code
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      final formattedCode = code.trim().toUpperCase();

      if (formattedCode == 'WELCOME50') {
        final discountVal = (cartTotal * 0.5 > 100) ? 100.0 : cartTotal * 0.5;
        state = OfferState(
          discount: discountVal,
          appliedCode: formattedCode,
          backendTotal: cartTotal - discountVal,
        );
        return true;
      } else if (formattedCode == 'FREEDEL') {
        state = OfferState(
          discount: 29.0, // Flat delivery fee discount
          appliedCode: formattedCode,
          backendTotal: cartTotal - 29.0,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid promo code. Try WELCOME50 or FREEDEL.',
        );
        return false;
      }
    }

    try {
      final response = await ApiClient.dio.post(
        '/customer/offers/validate',
        data: {
          'restaurant_id': restaurantId,
          'items': items,
          'code': code.trim().isNotEmpty ? code.trim() : null,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final discountVal = (data['discount_amount'] ?? data['discount'] as num?)?.toDouble() ?? 0.0;
        final finalTotal = (data['total_amount'] ?? data['total'] as num?)?.toDouble() ?? cartTotal;

        state = OfferState(
          discount: discountVal,
          appliedCode: code,
          backendTotal: finalTotal,
        );
        return true;
      }

      state = state.copyWith(isLoading: false, errorMessage: 'Failed to validate offer.');
      return false;
    } catch (e) {
      LoggerService.logger.e('Offer validation error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid offer code or connection error.',
      );
      return false;
    }
  }

  void removeOffer() {
    state = const OfferState();
  }
}

final offerProvider = StateNotifierProvider<OfferNotifier, OfferState>((ref) {
  return OfferNotifier();
});
