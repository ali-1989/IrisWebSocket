import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'socket_notifier.dart';

enum ConnectionStatus {
  none,
  connecting,
  connected,
  closed,
}
///==================================================================================================
class BaseWebSocket {
  SocketNotifier socketNotifier = SocketNotifier();
  ConnectionStatus connectionStatus = ConnectionStatus.none;
  String url;
  WebSocket? socket;
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
      socketNotifier = SocketNotifier();
    }

    try {
      connectionStatus = ConnectionStatus.connecting;

      if(allowSelfSigned){
        socket = await _connectForSelfSignedCert(url).then<WebSocket?>((value) => value).onError((error, st) => null);
      }
      else {
        socket = await WebSocket.connect(url).then<WebSocket?>((value) => value).onError((error, st) => null);
      }

      socket!.pingInterval = _ping;

      socketNotifier.open?.call();
      connectionStatus = ConnectionStatus.connected;

      socket?.listen((data) {
        socketNotifier.notifyData(data);
      }
      ,onError: (err) {
        socketNotifier.notifyError(Close(err.toString(), 1005));
      }
      , onDone: () {
        connectionStatus = ConnectionStatus.closed;
        socketNotifier.notifyClose(Close('ws connection closed', socket?.closeCode));
      }
      , cancelOnError: true);

      return;
    }
    on SocketException catch (e) {
      connectionStatus = ConnectionStatus.closed;
      socketNotifier.notifyError(Close(e.osError?.message, e.osError?.errorCode));
      return;
    }
    catch (e) {
      connectionStatus = ConnectionStatus.closed;
      socketNotifier.notifyError(Close(e.toString(), 0));
      return;
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
    socket?.close(status, reason);
  }

  void send(dynamic data) async {
    if (connectionStatus == ConnectionStatus.closed) {
      await connect();
    }

    socket?.add(data);
  }

  void dispose() {
    socketNotifier.dispose();
    isDisposed = true;
  }

  void emit(String event, dynamic data) {
    send(jsonEncode({'type': event, 'data': data}));
  }

  Future<WebSocket> _connectForSelfSignedCert(String url) async {
    try {
      final Random r = Random();
      final key = base64.encode(List<int>.generate(8, (_) => r.nextInt(255)));
      final client = HttpClient(context: SecurityContext());

      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        print('Base-WebSocket: Allow self-signed certificate => $host:$port. ');
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
