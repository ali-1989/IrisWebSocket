import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'package:iris_websocket/src/enums.dart';

import 'package:iris_websocket/src/socket_notifier.dart';

class BaseWebSocket with SocketNotifier {
  //SocketNotifier socketNotifier = SocketNotifier();
  ConnectionStatus connectionStatus = ConnectionStatus.none;
  bool _isDisposed = false;
  String url;
  late Duration _ping;
  late WebSocket socket;
  Timer? _pingTimer;

  bool get isDisposed => _isDisposed;

  BaseWebSocket(this.url, {Duration? ping}) {
    url = url.startsWith('https') ? url.replaceFirst('https:', 'wss:') : url.replaceFirst('http:', 'ws:');

    if(ping != null) {
      _ping = ping;
    }
    else {
      _ping = const Duration(minutes: 3);
    }
  }

  void connect() {
    try {
      if(_isDisposed){
        throw Exception('WebSocket is disposed.');
      }

      connectionStatus = ConnectionStatus.connecting;
      socket = WebSocket(url);

      socket.onOpen.listen((event) {
        connectionStatus = ConnectionStatus.connected;

        _pingTimer = Timer.periodic(_ping, (t) {
          socket.send('ping_pong');
        });

        notifyOpen();
      });

      socket.onMessage.listen((event) {
        notifyData(event.data);
      });

      socket.onClose.listen((e) {
        _pingTimer?.cancel();

        connectionStatus = ConnectionStatus.closed;
        notifyClose(CloseException(e.reason, e.code));
      });

      socket.onError.listen((event) {
        _pingTimer?.cancel();
        connectionStatus = ConnectionStatus.closed;
        notifyError(CloseException(event.toString(), 0));
      });
    }
    catch (e) {
      connectionStatus = ConnectionStatus.closed;
      _pingTimer?.cancel();
      notifyError(CloseException(e.toString(), 500));

      //  close(500, e.toString());
    }
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
      throw Exception('WebSocket not connected, your message not sent. ($data)');
    }
  }

  void emit(String event, dynamic data) {
    send(jsonEncode({eventKey: event, dataKey: data}));
  }

  void dispose() {
    disposeNotifier();
    _isDisposed = true;
  }
}
