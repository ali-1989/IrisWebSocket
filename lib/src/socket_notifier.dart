import 'dart:convert';


class CloseException {
  final String? message;
  final int? reason;

  CloseException(this.message, this.reason);

  @override
  String toString() {
    return 'WebSocket is Closed, code:$reason,  message:$message';
  }
}
///=============================================================================
typedef OpenEvent = void Function();
typedef CloseEvent = void Function(CloseException);
typedef SocketMessage = void Function(dynamic value);
///=============================================================================
mixin class SocketNotifier {
  final _onMessageListener = <SocketMessage>{};
  final _eventListeners = <String, Set<SocketMessage>>{};
  final _onCloseListeners = <CloseEvent>{};
  final _onErrorListeners = <CloseEvent>{};
  final _onOpenListeners = <OpenEvent>[];

  String _eventKey = 'event';
  String dataKey = 'data';

  String get eventKey => _eventKey;
  void set eventKey(String event) => _eventKey = event;

  void addOpenListener(OpenEvent listener) {
    _onOpenListeners.add(listener);
  }

  void removeOpenListener(OpenEvent listener) {
    _onOpenListeners.remove(listener);
  }

  void addMessageListener(SocketMessage listener) {
    _onMessageListener.add(listener);
  }

  void removeMessageListener(SocketMessage listener) {
    _onMessageListener.remove(listener);
  }

  void addEventListener(String event, SocketMessage listener) {
    if(!_eventListeners.containsKey(event)){
      _eventListeners[event] = <SocketMessage>{};
    }

    _eventListeners[event]!.add(listener);
  }

  void removeEventListener(String event, SocketMessage listener) {
    if(!_eventListeners.containsKey(event)){
     return;
    }

    _eventListeners[event]!.remove(listener);
  }

  void addCloseListener(CloseEvent listener) {
    _onCloseListeners.add(listener);
  }

  void removeCloseListener(CloseEvent listener) {
    _onCloseListeners.remove(listener);
  }

  void addErrorListener(CloseEvent listener) {
    _onErrorListeners.add((listener));
  }

  void removeErrorListener(CloseEvent listener) {
    _onErrorListeners.add((listener));
  }

  void notifyOpen() {
    for (final listener in _onOpenListeners) {
      try{
        print('@@@@@@@@@@ notify open');

        listener.call();
      }
      catch (e){/**/}
    }
  }

  void notifyData(dynamic data) {
    for (final listener in _onMessageListener) {
      try{
        listener.call(data);
      }
      catch (e){/**/}
    }

    _tryForEvent(data);
  }

  void notifyClose(CloseException err) {
    for (final listener in _onCloseListeners) {
      try{
        listener(err);
      }
      catch (e){/**/}
    }
  }

  void notifyError(CloseException err) {
    for (final listener in _onErrorListeners) {
      try{
        listener(err);
      }
      catch (e){/**/}
    }
  }

  void _tryForEvent(dynamic message) {
    try {
      final Map<String, dynamic> msg = jsonDecode(message);
      final event = msg[_eventKey];
      final data = msg[dataKey];

      if (_eventListeners.containsKey(event)) {
        for(final lis in _eventListeners[event]!){
          try{
            lis.call(data);
          }
          catch (e) {/**/}
        }
      }
    }
    catch (err) {/**/}
  }

  void disposeNotifier() {
    _onMessageListener.clear();
    _eventListeners.clear();
    _onCloseListeners.clear();
    _onErrorListeners.clear();
  }
}
