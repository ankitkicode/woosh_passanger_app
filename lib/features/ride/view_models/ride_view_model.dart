import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/di_providers.dart';
import '../models/ride_model.dart';

// ──── State ────────────────────────────────────────────────────────────────

class RideState {
  final RideLocation? pickup;
  final RideLocation? drop;
  final FareEstimate? fareEstimate;
  final RideModel? activeRide;
  final String paymentMethod; // 'cash' or 'wallet'
  final bool isLoading;
  final String? error;

  const RideState({
    this.pickup,
    this.drop,
    this.fareEstimate,
    this.activeRide,
    this.paymentMethod = 'cash',
    this.isLoading = false,
    this.error,
  });

  RideState copyWith({
    RideLocation? pickup,
    RideLocation? drop,
    FareEstimate? fareEstimate,
    RideModel? activeRide,
    String? paymentMethod,
    bool? isLoading,
    String? error,
  }) {
    return RideState(
      pickup: pickup ?? this.pickup,
      drop: drop ?? this.drop,
      fareEstimate: fareEstimate ?? this.fareEstimate,
      activeRide: activeRide ?? this.activeRide,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ──── ViewModel ────────────────────────────────────────────────────────────

class RideViewModel extends StateNotifier<RideState> {
  final Ref _ref;
  Timer? _pollingTimer;

  RideViewModel(this._ref) : super(const RideState());

  void setPickup(RideLocation location) {
    state = state.copyWith(pickup: location, fareEstimate: null, error: null);
  }

  void setDrop(RideLocation location) {
    state = state.copyWith(drop: location, fareEstimate: null, error: null);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  /// Estimate fare from backend
  Future<bool> estimateFare() async {
    if (state.pickup == null || state.drop == null) {
      state = state.copyWith(error: 'Please set pickup and drop locations');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.post('/ride/estimate', data: {
        'pickup': state.pickup!.toJson(),
        'drop': state.drop!.toJson(),
      });
      final estimate = FareEstimate.fromJson(response.data['data'] as Map<String, dynamic>);
      state = state.copyWith(fareEstimate: estimate, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  /// Book a ride
  Future<String?> requestRide() async {
    if (state.pickup == null || state.drop == null) return null;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.post('/ride/request', data: {
        'pickup': state.pickup!.toJson(),
        'drop': state.drop!.toJson(),
        'paymentMethod': state.paymentMethod,
      });
      final ride = RideModel.fromJson(response.data['data'] as Map<String, dynamic>);
      state = state.copyWith(activeRide: ride, isLoading: false);
      return ride.id;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return null;
    }
  }

  /// Get ride details (used for polling)
  Future<RideModel?> getRideDetails(String rideId) async {
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.get('/ride/$rideId');
      final ride = RideModel.fromJson(response.data['data'] as Map<String, dynamic>);
      state = state.copyWith(activeRide: ride);
      return ride;
    } catch (_) {
      return state.activeRide;
    }
  }

  /// Start polling ride status every 5 seconds
  void startPolling(String rideId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      getRideDetails(rideId);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Cancel ride
  Future<bool> cancelRide(String rideId) async {
    try {
      final api = _ref.read(apiClientProvider);
      await api.put('/ride/$rideId/cancel', data: {'reason': 'Passenger cancelled'});
      state = state.copyWith(activeRide: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: _extractError(e));
      return false;
    }
  }

  /// Rate a completed ride
  Future<bool> rateRide(String rideId, int rating, {String? comment}) async {
    try {
      final api = _ref.read(apiClientProvider);
      await api.put('/ride/$rideId/rate', data: {
        'rating': rating,
        if (comment != null) 'comment': comment,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Trigger SOS
  Future<void> triggerSOS(String rideId) async {
    try {
      final api = _ref.read(apiClientProvider);
      await api.post('/tracking/sos', data: {'rideId': rideId});
    } catch (_) {}
  }

  void clearRide() {
    state = const RideState();
    stopPolling();
  }

  String _extractError(dynamic e) {
    final msg = e.toString();
    if (msg.length > 120) return 'Something went wrong. Please try again.';
    return msg.replaceAll('Exception: ', '');
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final rideViewModelProvider = StateNotifierProvider<RideViewModel, RideState>((ref) {
  return RideViewModel(ref);
});
