import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import '../models/transformer.dart';

import '../config.dart';

class SocketService {
  late IO.Socket socket;
  final String _socketUrl = Config.socketUrl;

  // Callback to handle incoming transformer updates
  final Function(Transformer) onTransformerUpdated;
  
  // Callback when another engineer accepts a job
  final Function(String)? onJobAccepted;

  SocketService({required this.onTransformerUpdated, this.onJobAccepted}) {
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io(_socketUrl, IO.OptionBuilder()
      .setTransports(['websocket']) // for Flutter or Web
      .enableAutoConnect()
      .build()
    );

    socket.onConnect((_) {
      if (kDebugMode) {
        print('Connected to Socket.io Server');
      }
    });

    socket.on('transformerUpdate', (data) {
      if (kDebugMode) {
        print('Received transformer update via socket: $data');
      }
      try {
        final updatedTransformer = Transformer.fromJson(data);
        onTransformerUpdated(updatedTransformer);
      } catch (e) {
        if (kDebugMode) {
            print('Error parsing socket data: $e');
        }
      }
    });

    socket.on('jobAccepted', (data) {
      if (kDebugMode) {
        print('Job accepted by someone else: $data');
      }
      if (onJobAccepted != null && data['transformerId'] != null) {
        onJobAccepted!(data['transformerId']);
      }
    });

    socket.onDisconnect((_) {
      if (kDebugMode) {
        print('Disconnected from Socket.io Server');
      }
    });
  }

  void dispose() {
    socket.disconnect();
    socket.dispose();
  }

  void acceptJob(String transformerId) {
    socket.emit('acceptJob', {'transformerId': transformerId});
  }
}
