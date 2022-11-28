import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'socket_notifier.dart';

enum ConnectionStatus {
  none,
  connecting,
  connected,
  closed,
}
///==========================================================================================================
class BaseWebSocket {
  SocketNotifier socketNotifier = SocketNotifier();
  ConnectionStatus connectionStatus = ConnectionStatus.none;
  bool isDisposed = false;
  String url;
  late Duration _ping;
  late WebSocket socket;
  Timer? _pingTimer;

  BaseWebSocket(this.url, {Duration? ping}) {
    url = url.startsWith('https') ? url.replaceAll('https:', 'wss:') : url.replaceAll('http:', 'ws:');

    if(ping != null) {
      _ping = ping;
    } else {
      _ping = const Duration(minutes: 4);
    }
  }

  void connect() {
    try {
      connectionStatus = ConnectionStatus.connecting;
      socket = WebSocket(url);

      socket.onOpen.listen((e) {
        socketNotifier.open?.call();

        _pingTimer = Timer.periodic(_ping, (t) {
          socket.send('');
        });

        connectionStatus = ConnectionStatus.connected;
      });

      socket.onMessage.listen((event) {
        socketNotifier.notifyData(event.data);
      });

      socket.onClose.listen((e) {
        _pingTimer?.cancel();

        connectionStatus = ConnectionStatus.closed;
        socketNotifier.notifyClose(Close(e.reason, e.code));
      });
      socket.onError.listen((event) {
        _pingTimer?.cancel();
        socketNotifier.notifyError(Close(event.toString(), 0));
        connectionStatus = ConnectionStatus.closed;
      });
    }
    catch (e) {
      _pingTimer?.cancel();
      socketNotifier.notifyError(Close(e.toString(), 500));
      connectionStatus = ConnectionStatus.closed;
      //  close(500, e.toString());
    }
  }

  void onOpen(OpenSocket fn) {
    socketNotifier.open = fn;
  }

  void onClose(CloseSocket fn) {
    socketNotifier.addCloses(fn);
  }

  void onError(CloseSocket fn) {
    socketNotifier.addErrors(fn);
  }

  void onMessage(MessageSocket fn) {
    socketNotifier.addMessages(fn);
  }

  void on(String event, MessageSocket message) {
    socketNotifier.addEvents(event, message);
  }

  void close([int? status, String? reason]) {
    socket.close(status, reason);
  }

  void send(dynamic data) {
    if (connectionStatus == ConnectionStatus.closed) {
      connect();
    }

    if (socket.readyState == WebSocket.OPEN) {
      socket.send(data);
    }
    else {
      //prin('WebSocket not connected, message $data not sent');
      throw Exception('WebSocket not connected, message $data not sent');
    }
  }

  void emit(String event, dynamic data) {
    send(jsonEncode({'type': event, 'data': data}));
  }

  void dispose() {
    socketNotifier.dispose();
    isDisposed = true;
  }
}
