import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class RawDatagramSocketService {
  RawDatagramSocket? _socket;

  Future<RawDatagramSocketService> bind(
    InternetAddress address,
    int port,
  ) async {
    _socket = await RawDatagramSocket.bind(address, port);
    return this;
  }

  StreamSubscription<RawSocketEvent> listen(
    void Function(RawSocketEvent event)? onData,
  ) {
    return _socket!.listen(onData);
  }

  Datagram? receive() {
    return _socket!.receive();
  }

  int send(Uint8List bytes, InternetAddress address, int port) {
    return _socket!.send(bytes, address, port);
  }

  void close() {
    _socket!.close();
  }
}
