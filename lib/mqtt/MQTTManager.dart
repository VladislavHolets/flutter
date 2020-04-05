import 'package:flutter/cupertino.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:roboremote/mqtt/state/MQTTAppState.dart';

class MQTTManager {
  // Private instance of client
  final MQTTAppState _currentState;
  MqttClient _client;
  final String _identifier;
  final String _host;
  final String _topic;
  final String _user;
  final String _password;

//final int _port;
  // Constructor
  MQTTManager({
    @required String host,
    @required String topic,
    @required String identifier,
    @required MQTTAppState state,
    String user = null,
    String password = null,
    //int port
  })  : _identifier = identifier,
        _host = host,
        _topic = topic,
        _user = user,
        _password = password,
        _currentState = state;

  void initializeMQTTClient() {
    _client = MqttServerClient(_host, _identifier);
    _client.keepAlivePeriod = 20;
    //_client.checkCredentials(_user, _password);
    _client.onDisconnected = onDisconnected;
    _client.logging(on: true);
    // _client.port=_port;
    /// Add the successful connection callback
    _client.onConnected = onConnected;
    _client.onSubscribed = onSubscribed;

    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier(_identifier)
        .withWillTopic(
            'willtopic') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    print('Mosquitto client connecting....');
    _client.connectionMessage = connMess;
  }

  MQTTAppState getState() {
    return _currentState;
  }

  // Connect to the host
  void connect() async {
    assert(_client != null);
    try {
      print('Mosquitto start client connecting....');
      _currentState.setAppConnectionState(MQTTAppConnectionState.connecting);
      if (_user != null && _password != null)
        await _client.connect(_user, _password);
      else
        await _client.connect();
    } on Exception catch (e) {
      print('client exception - $e');
      disconnect();
    }
  }

  void disconnect() {
    print('Disconnected');
    _client.disconnect();
  }

  void publish(String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(_topic, MqttQos.exactlyOnce, builder.payload);
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    print('Subscription confirmed for topic $topic');
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    print('OnDisconnected client callback - Client disconnection');
    if (_client.connectionStatus.returnCode ==
        MqttConnectReturnCode.solicited) {
      print('OnDisconnected callback is solicited, this is correct');
    }
    _currentState.setAppConnectionState(MQTTAppConnectionState.disconnected);
  }

  /// The successful connect callback
  void onConnected() {
    _currentState.setAppConnectionState(MQTTAppConnectionState.connected);
    print('Mosquitto client connected....');
    _client.subscribe(_topic, MqttQos.atLeastOnce);
    _client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload;
      final String pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      _currentState.setReceivedText(pt);

      /// The above may seem a little convoluted for users only interested in the
      /// payload, some users however may be interested in the received publish message,
      /// lets not constrain ourselves yet until the package has been in the wild
      /// for a while.
      /// The payload is a byte buffer, this will be specific to the topic
      print(
          'Change notification:: topic is <${c[0]
              .topic}>, payload is <-- $pt -->');
      print('');
    });
    print(
        'OnConnected client callback - Client connection was sucessful');
  }
}
