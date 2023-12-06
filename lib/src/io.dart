import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:iris_websocket/src/enums.dart';

import 'package:iris_websocket/src/socket_notifier.dart';


class BaseWebSocket with SocketNotifier {
  //SocketNotifier socketNotifier = SocketNotifier();
  ConnectionStatus connectionStatus = ConnectionStatus.none;
  String url;
  WebSocket? wSocket;
  bool isDisposed = false;
  bool allowSelfSigned = false;
  Duration? _ping;

  BaseWebSocket(this.url, {Duration? ping}){
    if(ping != null){
      _ping = ping;
    }
  }

  Future connect() async {
    if (isDisposed) {
      throw Exception('WebSocket is disposed');
    }

    try {
      connectionStatus = ConnectionStatus.connecting;

      if(allowSelfSigned){
        wSocket = await _connectForSelfSignedCert(url).then<WebSocket?>((value) => value).onError((error, st) => null);
      }
      else {
        wSocket = await WebSocket.connect(url).then<WebSocket?>((value) => value).onError((error, st) => null);
      }

      print('@@@@@@@@@@ ${(wSocket != null)}');
      if(wSocket != null){
        connectionStatus = ConnectionStatus.connected;
        notifyOpen();
      }
      else {
        connectionStatus = ConnectionStatus.closed;
        notifyError(CloseException('Can not connect to ws.', 1));
      }
      print('@@@@@@@@@@ set ping');

      wSocket?.pingInterval = _ping;
      
      wSocket?.listen((data) {
        notifyData(data);
        },
        onError: (err) {
          notifyError(CloseException(err.toString(), 0));
        },
        onDone: () {
          connectionStatus = ConnectionStatus.closed;
          notifyClose(CloseException('WebSocket connection closed by server', wSocket?.closeCode));
        },
         cancelOnError: true,
      );
    }
    on SocketException catch (e) {
      connectionStatus = ConnectionStatus.closed;
      notifyError(CloseException(e.osError?.message, e.osError?.errorCode));
    }
    catch (e) {
      connectionStatus = ConnectionStatus.closed;
      notifyError(CloseException(e.toString(), 100));
    }
  }

  void close([int? status, String? reason]) {
    wSocket?.close(status, reason);
  }

  Future<void> send(dynamic data) async {
    if (connectionStatus == ConnectionStatus.closed) {
      await connect();
    }

    wSocket?.add(data);
  }

  void dispose() {
    disposeNotifier();
    isDisposed = true;
  }

  void emit(String event, dynamic data) {
    send(jsonEncode({eventKey: event, dataKey: data}));
  }

  Future<WebSocket> _connectForSelfSignedCert(String url) async {
    try {
      final Random r = Random();
      final key = base64.encode(List<int>.generate(8, (_) => r.nextInt(255)));
      final client = HttpClient(context: SecurityContext());

      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        return true;
      };

      final request = await client.getUrl(Uri.parse(url));
      request.headers.add('Connection', 'Upgrade');
      request.headers.add('Upgrade', 'websocket');
      request.headers.add('Sec-WebSocket-Version', '13');
      request.headers.add('Sec-WebSocket-Key', key.toLowerCase());

      final response = await request.close();
      // ignore: close_sinks
      final socket = await response.detachSocket();
      final webSocket = WebSocket.fromUpgradedSocket(
        socket,
        protocol: 'signaling',
        serverSide: false,
      );

      return webSocket;
    }
    catch (e) {
      rethrow;
    }
  }
}
