import 'dart:async';
import 'dart:io';
import 'package:xmlrpc_server/xmlrpc_server.dart';
import 'package:xml_rpc/client.dart' as xml_rpc;
import 'package:xml/xml.dart';

import 'ros_message.dart';
import 'type_apis/int_apis.dart';

//TODO: RosSubscriber uses static MASTER hostname
class RosPublisher<Message extends RosMessage> {
  final String nodeName;
  final String topic;
  final Message type;
  final List<Socket> _publishSockets = <Socket>[];

  XmlRpcServer _server;
  ServerSocket _tcpros_server;

  RosPublisher(this.nodeName, this.topic, this.type,
      {Duration publishInterval}) {
    var ip = '';

    _server = XmlRpcServer(host: InternetAddress.anyIPv4, port: 54231);
    _server.bind('requestTopic', onTopicRequest);
    _server.startServer();

    ServerSocket.bind(InternetAddress.loopbackIPv4, 33241).then((server) {
      _tcpros_server = server;
      server.listen((socket) {
        socket.listen((data) {
          socket.add(_tcpros_header());
          _publishSockets.add(socket);
        });
      });
    });

    Timer.periodic(
        publishInterval ?? Duration(seconds: 1), (_) => publishData());
  }

  void publishData() {
    _publishSockets.forEach((socket) {
      var packet = <int>[];
      var data = type.toBytes();
      packet.addAll((data.length).toBytes());
      packet.addAll(data);
      socket.add(packet);
    });
  }

  List<int> _tcpros_header() {
    var messageHeader = type.binaryHeader;

    var header = <int>[];
    header.addAll(messageHeader.length.toBytes());
    header.addAll(messageHeader);
    return header;
  }

  Future<XmlDocument> onTopicRequest(List<dynamic> values) async {
    final requestedSettings = values[2][0];
    if (requestedSettings.contains('TCPROS')) {
      return generateXmlResponse([
        [
          1,
          'ready on ${_tcpros_server.address.address}:${_tcpros_server.port}',
          ['TCPROS', _tcpros_server.address.address, _tcpros_server.port]
        ]
      ]);
    } else {
      throw ArgumentError();
    }
  }

  void register() async {
    try {
      final result = await xml_rpc
          .call('http://DESKTOP-L2R4GKN:11311/', 'registerPublisher', [
        '/$nodeName',
        '/$topic',
        '${type.message_type}',
        'http://${_server.host}:${_server.port}/'
      ]);
      print(result);
    } catch (e) {
      print(e);
    }
  }

  void unregister() async {
    try {
      final result = await xml_rpc.call(
          'http://DESKTOP-L2R4GKN:11311',
          'unregisterPublisher',
          ['/$nodeName', '/$topic', 'http://${_server.host}:${_server.port}/']);
      print(result);
    } catch (e) {
      print(e);
    }
  }
}
