import 'dart:convert';

class Close {
  final String? message;
  final int? reason;

  Close(this.message, this.reason);

  @override
  String toString() {
    return 'Ws Closed by server, $reason,  $message';
  }
}
///=========================================================================================================
typedef OpenSocket = void Function();
typedef CloseSocket = void Function(Close);
typedef MessageSocket = void Function(dynamic val);
///=========================================================================================================
class SocketNotifier {
  final _onMessages = <MessageSocket>[];
  final _onEvents = <String, MessageSocket>{};
  final _onCloses = <CloseSocket>[];
  final _onErrors = <CloseSocket>[];
  OpenSocket? open;

  void addMessages(MessageSocket socket) {
    _onMessages.add((socket));
  }

  void addEvents(String event, MessageSocket socket) {
    _onEvents[event] = socket;
  }

  void addCloses(CloseSocket socket) {
    _onCloses.add(socket);
  }

  void addErrors(CloseSocket socket) {
    _onErrors.add((socket));
  }

  void notifyData(dynamic data) {
    for (var item in _onMessages) {
      item(data);
    }

    _tryOn(data);
  }

  void notifyClose(Close err) {
    for (var item in _onCloses) {
      item(err);
    }
  }

  void notifyError(Close err) {
    for (var item in _onErrors) {
      item(err);
    }
  }

  void _tryOn(dynamic message) {
    try {
      final Map<String, dynamic> msg = jsonDecode(message);
      final event = msg['type'];
      final data = msg['data'];

      if (_onEvents.containsKey(event)) {
        _onEvents[event]?.call(data);
      }
    }
    catch (err) {
      return;
    }
  }

  void dispose() {
    _onMessages.clear();
    _onEvents.clear();
    _onCloses.clear();
    _onErrors.clear();
  }
}
