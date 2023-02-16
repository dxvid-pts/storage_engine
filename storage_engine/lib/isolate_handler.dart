import 'dart:async';
import 'dart:isolate';
import 'package:storage_engine/box_adapter.dart';
import 'package:stream_channel/isolate_channel.dart';

// ------------ internal variables ------------
final _rPort = ReceivePort();
late final IsolateChannel _channelA;

bool _isolateRunning = false;

late final Stream _broadCastStream;

// ------------ external api ------------

Future<void> spawnIsolateIfNotRunning() async {
  if (_isolateRunning) return;
  _isolateRunning = true;

  _channelA = IsolateChannel.connectReceive(_rPort);
  _broadCastStream = _channelA.stream.asBroadcastStream().asBroadcastStream();

  await Isolate.spawn(_isolateRunner, _rPort.sendPort);
}

Future<void> registerIsolateBox({
  required String boxKey,
  required BoxAdapter adapter,
}) async {
  String jobId = _generateJobId();
  _sendToIsolate(jobId, RegisterIsolateBoxStruct(boxKey, adapter));

  //wait until the isolate is done
  await _getIsolateMessageWithId(jobId);
}

Future<dynamic> runBoxFunctionInIsolate({
  required BoxFunctionType type,
  String? key,
  dynamic value,
  required String collectionKey,
}) {
  String jobId = _generateJobId();
  _sendToIsolate(
      jobId, BoxFunctionInIsolateStruct(type, key, value, collectionKey));

  //return job result
  return _getIsolateMessageWithId(jobId);
}

//------------ isolate runner ------------

Future<void> _isolateRunner(SendPort sPort) async {
  print('debugging: spawned isolate.');
  final Map<String, BoxAdapter> adapters = {};

  IsolateChannel channelB = IsolateChannel.connectSend(sPort);
  channelB.stream.listen((wrapper) {
    //only listen on _IsolateJobs
    if (!wrapper is _IsolateJob) {
      return;
    }
    final jobId = wrapper.jobId;
    final message = wrapper.body;

    print("debugging: received isolate message: ${message.runtimeType}");
    if (message is BoxFunctionInIsolateStruct) {
      //dont wait for futures so we dont stop the isolate (return the future -> main thread waits)
      try {
        var result;
        switch (message.type) {
          case BoxFunctionType.init:
            result = adapters[message.collectionKey]?.init(message.key!);
            break;
          case BoxFunctionType.containsKey:
            result = adapters[message.collectionKey]?.containsKey(message.key!);
            break;
          case BoxFunctionType.get:
            result = adapters[message.collectionKey]?.get(message.key!);
            break;
          case BoxFunctionType.getAll:
            result = adapters[message.collectionKey]
                ?.getAll(pagination: message.value);
            break;
          case BoxFunctionType.put:
            result = adapters[message.collectionKey]
                ?.put(message.key!, message.value!);
            break;
          case BoxFunctionType.putAll:
            result = adapters[message.collectionKey]?.putAll(message.value!);
            break;
          case BoxFunctionType.delete:
            result = adapters[message.collectionKey]?.remove(message.key!);
            break;
          case BoxFunctionType.clear:
            result = adapters[message.collectionKey]?.clear();
            break;
          default:
            //always send something as the sender expects a response
            result = null;
        }
        channelB.sink.add(_IsolateJob(jobId, result));
      } catch (_) {
        //always send something as the sender expects a response
        channelB.sink.add(null);
      }
    } else if (message is RegisterIsolateBoxStruct) {
      //register adapter for later use if message is RegisterIsolateBoxStruct
      adapters[message.boxKey] = message.adapter;
      channelB.sink.add(_IsolateJob(jobId, true));
    } else if (message is ExitIsolateStruct) {
      print("exiting isolate");
      Isolate.exit();
    }
  });
}

// --------- isolate communication structs ---------

class _IsolateJob {
  final String jobId;
  final dynamic body;

  const _IsolateJob(this.jobId, this.body);
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
  init,
  containsKey,
  get,
  getAll,
  put,
  putAll,
  delete,
  clear,
}

// --------- Helper functions ---------

String _generateJobId() => DateTime.now().microsecondsSinceEpoch.toString();

Future<dynamic> _getIsolateMessageWithId(String jobId) async =>
    (await _broadCastStream.firstWhere((item) => item.jobId == jobId)).body;

void _sendToIsolate(String jobId, dynamic body) {
  _channelA.sink.add(_IsolateJob(jobId, body));
}
