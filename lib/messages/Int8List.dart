import 'dart:typed_data';
import 'package:ros_nodes/src/ros_message.dart';
import 'package:ros_nodes/src/type_apis/int_apis.dart';

class RosInt8List implements BinaryConvertable {
  Int8List list;

  RosInt8List({Int8List list}) {
    this.list = list ?? Int8List(0);
  }

  @override
  int fromBytes(Uint8List bytes, {int offset = 0}) {
    var size = ByteData.view(bytes.buffer).getUint32(offset, Endian.little);
    offset += 4;
    list = Int8List.fromList(bytes.sublist(offset, offset + size));
    return 4 + size;
  }

  @override
  List<int> toBytes() {
    final len = list.length;
    var bytes = Uint8List(4 + len);
    bytes.setRange(0, 4, len.toBytes());
    bytes.setRange(4, bytes.length, list);
    return bytes;
  }

  @override
  String toString() {
    return list.toString();
  }
}
