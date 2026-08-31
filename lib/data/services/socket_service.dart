import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'dart:io';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;

  // Listeners
  Function(Map<String, dynamic>)? onLocationUpdate;
  Function(Map<String, dynamic>)? onRiderStatusChanged;

  String get _socketUrl {
    return 'https://wooshride.in';
  }

  void connect() {
    if (socket != null && socket!.connected) return;

    socket = IO.io(_socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build()
    );

    socket!.connect();

    socket!.onConnect((_) {
      print('[Socket] Connected to backend');
      // Join the global passenger home room to receive updates from all online riders
      socket!.emit('passenger:join_home');
    });

    socket!.on('location:update', (data) {
      if (onLocationUpdate != null) {
        onLocationUpdate!(data);
      }
    });

    socket!.on('rider:status_changed', (data) {
      if (onRiderStatusChanged != null) {
        onRiderStatusChanged!(data);
      }
    });

    socket!.onDisconnect((_) {
      print('[Socket] Disconnected from backend');
    });
  }

  void joinRideRoom(String rideId) {
    if (socket != null && socket!.connected) {
      socket!.emit('passenger:join_ride', {'rideId': rideId});
    }
  }

  void disconnect() {
    socket?.disconnect();
  }
}
