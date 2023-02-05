import 'dart:isolate';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:storage_engine/box_adapter.dart';

final mainPort = ReceivePort();
late final StreamQueue _events;
late final SendPort _mainSendPort;
bool _isolateRunning = false;

Future<void> spawnIsolateIfNotRunning() async {
  if (_isolateRunning) return;
  _isolateRunning = true;

  await Isolate.spawn(_isolateRunner, mainPort.sendPort);

  // Convert the ReceivePort into a StreamQueue to receive messages from the
  // spawned isolate using a pull-based interface. Events are stored in this
  // queue until they are accessed by `events.next`.
  _events = StreamQueue<dynamic>(mainPort);

  // The first message from the spawned isolate is a SendPort. This port is
  // used to communicate with the spawned isolate.
  _mainSendPort = await _getNextIsolateMessage();
}

Future<dynamic> _getNextIsolateMessage() => _events.next;

/*Future<dynamic> runFunctionInIsolate(Function function) {
  mainSendPort.send(function);
  return _getNextIsolateMessage();
}*/

Future<void> registerIsolateBox({
  required String boxKey,
  required BoxAdapter adapter,
}) async {
  _mainSendPort.send(RegisterIsolateBoxStruct(boxKey, adapter));
  await _getNextIsolateMessage();
}

Future<dynamic> runBoxFunctionInIsolate({
  required BoxFunctionType type,
  String? key,
  dynamic value,
  required String collectionKey,
}) {
  _mainSendPort
      .send(BoxFunctionInIsolateStruct(type, key, value, collectionKey));
  return _getNextIsolateMessage();
}

void _isolateRunner(SendPort p) async {
  debugPrint('Spawned isolate started.');
  final Map<String, BoxAdapter> adapters = {};

  // Send a SendPort to the main isolate so that it can send JSON strings to
  // this isolate.
  final commandPort = ReceivePort();
  p.send(commandPort.sendPort);

  // Wait for messages from the main isolate.
  await for (final message in commandPort) {
    debugPrint("received message: ${message.runtimeType}");
    if (message is BoxFunctionInIsolateStruct) {
      //dont wait for futures so we dont stop the isolate (return the future -> main thread waits)
      try {
        switch (message.type) {
          case BoxFunctionType.containsKey:
            p.send(adapters[message.collectionKey]?.containsKey(message.key!));
            break;
          case BoxFunctionType.get:
            p.send(adapters[message.collectionKey]?.get(message.key!));
            break;
          case BoxFunctionType.getKeys:
            p.send(adapters[message.collectionKey]?.getKeys());
            break;
          case BoxFunctionType.getValues:
            p.send(adapters[message.collectionKey]?.getValues());
            break;
          case BoxFunctionType.put:
            p.send(adapters[message.collectionKey]
                ?.put(message.key!, message.value!));
            break;
          case BoxFunctionType.putAll:
            p.send(adapters[message.collectionKey]?.putAll(message.value!));
            break;
          case BoxFunctionType.delete:
            p.send(adapters[message.collectionKey]?.remove(message.key!));
            break;
          case BoxFunctionType.clear:
            p.send(adapters[message.collectionKey]?.clear());
            break;
          default:
            //always send something as the sender expects a response
            p.send(null);
        }
      } catch (_) {
        //always send something as the sender expects a response
        p.send(null);
      }
    } else if (message is RegisterIsolateBoxStruct) {
      //register adapter for later use if message is RegisterIsolateBoxStruct
      adapters[message.boxKey] = message.adapter;
      p.send(true);
    } else if (message is ExitIsolateStruct) {
      Isolate.exit();
    }

    // Send the result to the main isolate.
  }
}

class ExitIsolateStruct {}

class RegisterIsolateBoxStruct {
  final String boxKey;
  final BoxAdapter adapter;

  const RegisterIsolateBoxStruct(this.boxKey, this.adapter);
}

class BoxFunctionInIsolateStruct {
  final BoxFunctionType type;
  final String? key;
  final dynamic value;
  final String collectionKey;

  const BoxFunctionInIsolateStruct(
      this.type, this.key, this.value, this.collectionKey);
}

enum BoxFunctionType {
  containsKey,
  get,
  getValues,
  getKeys,
  put,
  putAll,
  delete,
  clear,
}
