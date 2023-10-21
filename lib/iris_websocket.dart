library iris_websocket;

import 'src/html.dart' if (dart.library.io) 'src/io.dart';

export 'package:iris_websocket/src/socket_notifier.dart';

class GetSocket extends BaseWebSocket {
  GetSocket(String url, {Duration? ping}) : super(url, ping: ping);
}
