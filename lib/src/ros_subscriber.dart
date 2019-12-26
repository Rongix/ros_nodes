import 'dart:convert';
import 'dart:io';
import 'package:xmlrpc_server/xmlrpc_server.dart';
import 'package:xml_rpc/client.dart' as xml_rpc;
import 'package:xml/xml.dart';

import 'type_apis/int_apis.dart';
import 'ros_message.dart';

//TODO: RosSubscriber uses static MASTER hostname
class RosSubscriber<Message extends RosMessage> {
  final String nodeName;
  final String topic;
  final Message type;
  final Map<String, Socket> _tcprosConnections = {};

  XmlRpcServer _server;
  Function onValueUpdate;

  RosSubscriber(this.nodeName, this.topic, this.type) {
    _server = XmlRpcServer(host: InternetAddress.anyIPv4, port: 21451);
    _server.bind('publisherUpdate', onPublisherUpdate);
    _server.startServer();
  }

  List<int> _tcpros_header() {
    final callerId = 'callerid=/$nodeName';
    final tcpNoDelay = 'tcp_nodelay=0';
    final topic = 'topic=/${this.topic}';

    var messageHeader = type.binaryHeader;

    var header = <int>[];
    header.addAll((messageHeader.length +
            4 +
            callerId.length +
            4 +
            topic.length +
            4 +
            tcpNoDelay.length)
        .toBytes());
    header.addAll(messageHeader);
    header.addAll(callerId.length.toBytes());
    header.addAll(utf8.encode(callerId));
    header.addAll(tcpNoDelay.length.toBytes());
    header.addAll(utf8.encode(tcpNoDelay));
    header.addAll(topic.length.toBytes());
    header.addAll(utf8.encode(topic));
    return header;
  }

  Future<XmlDocument> onPublisherUpdate(List<dynamic> values) async {
    //TODO: values[0] is name of the node calling api
    //TODO: values[0] is operation result if called master

    _tcprosConnections.removeWhere((x, connection) {
      final remove = !(values[2] as List).contains(x);
      if (remove) {
        connection.close();
      }
      return remove;
    });

    for (var connection in values[2]) {
      final response = await xml_rpc.call(connection, 'requestTopic', [
        '/$nodeName',
        '/$topic',
        [
          ['TCPROS']
        ]
      ]);

      var connectionValues = response[2];
      if (!_tcprosConnections.keys.contains(connection)) {
        var socket =
            await Socket.connect(connectionValues[1], connectionValues[2]);

        socket.add(_tcpros_header());

        var done = false;

        socket.listen((data) {
          if (!done) {
            done = true;
            return;
          }
          type.fromBytes(data, offset: 4);
          if (onValueUpdate != null) onValueUpdate();
        });

        _tcprosConnections.putIfAbsent(connection, () => socket);
      }
    }
    return generateXmlResponse([1]);
  }

  void subscribe() async {
    try {
      final result = await xml_rpc
          .call('http://DESKTOP-L2R4GKN:11311/', 'registerSubscriber', [
        '/$nodeName',
        '/$topic',
        '${type.message_type}',
        'http://${_server.host}:${_server.port}/'
      ]);
      await onPublisherUpdate(result);
      print(result);
    } catch (e) {
      print(e);
    }
  }

  void unsubscribe() async {
    try {
      final result = await xml_rpc.call(
          'http://DESKTOP-L2R4GKN:11311',
          'unregisterSubscriber',
          ['/$nodeName', '/$topic', 'http://${_server.host}:${_server.port}/']);
      print(result);
    } catch (e) {
      print(e);
    }
  }
}
