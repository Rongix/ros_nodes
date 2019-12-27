import 'package:ros_nodes/messages/std_msgs/String.dart';
import 'package:ros_nodes/ros_nodes.dart';

void main() {
  var msg = StdMsgsString();
  var subscriber =
      RosSubscriber('ros_nodes_example_subscriber', 'chatter', msg);
  subscriber.subscribe();
  subscriber.onValueUpdate.listen((type) => print('Listener 1: ${type.data}'));
  subscriber.onValueUpdate.listen((_) => print('Listener 2: ${msg.data}'));
}
