library iris_websocket;

import 'src/io.dart' if (dart.library.html) 'src/html.dart';

export 'package:iris_websocket/src/socket_notifier.dart';

class IrisWebSocket extends BaseWebSocket {
  IrisWebSocket(super.url, {super.ping});
}
