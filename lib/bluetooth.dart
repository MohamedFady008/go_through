import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  BluetoothService._internal();
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;

  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  bool _bluetoothState = false;
  bool _isConnecting = false;
  bool _isntConnected = true;
  bool _permissionsRequested = false;
  BluetoothConnection? _connection;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _deviceConnected;
  String? _cachedDeviceAddress;
  StreamSubscription<BluetoothState>? _stateSubscription;
  final String specificDeviceName = "GoThrough Wheelchair";
  Function(bool, bool, bool)? onConnectionStateChanged;

  static final Uint8List _forwardBytes = Uint8List.fromList(<int>[102]); // f
  static final Uint8List _backwardBytes = Uint8List.fromList(<int>[98]); // b
  static final Uint8List _leftBytes = Uint8List.fromList(<int>[108]); // l
  static final Uint8List _rightBytes = Uint8List.fromList(<int>[114]); // r
  static final Uint8List _stopBytes = Uint8List.fromList(<int>[115]); // s
  static final Map<String, Uint8List> _knownPayloadByCommand =
      <String, Uint8List>{
    'f': _forwardBytes,
    'b': _backwardBytes,
    'l': _leftBytes,
    'r': _rightBytes,
    's': _stopBytes,
  };
  static final Map<int, Uint8List> _knownPayloadByCodeUnit = <int, Uint8List>{
    102: _forwardBytes,
    98: _backwardBytes,
    108: _leftBytes,
    114: _rightBytes,
    115: _stopBytes,
  };

  Future<void> requestPermission() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;
    await Future.wait([
      Permission.location.request(),
      Permission.bluetooth.request(),
      Permission.bluetoothScan.request(),
      Permission.bluetoothConnect.request(),
    ]);
  }

  Future<void> getDevices() async {
    final res = await _bluetooth.getBondedDevices();
    _devices = res;
  }

  void sendData(String data) {
    final connection = _connection;
    if (connection?.isConnected ?? false) {
      connection!.output.add(
        _knownPayloadByCommand[data] ?? Uint8List.fromList(ascii.encode(data)),
      );
    }
  }

  void sendCommandCodeUnit(int codeUnit) {
    final connection = _connection;
    if (connection?.isConnected ?? false) {
      final payload = _knownPayloadByCodeUnit[codeUnit];
      if (payload != null) {
        connection!.output.add(payload);
      }
    }
  }

  Future<bool> _connectToAddress(String address) async {
    final connection = await BluetoothConnection.toAddress(address);
    _connection = connection;
    _isntConnected = !connection.isConnected;
    return connection.isConnected;
  }

  Future<void> connectToDeviceByName() async {
    if (_isConnecting) return;
    if (_connection?.isConnected ?? false) {
      _isntConnected = false;
      notifyConnectionStateChanged();
      return;
    }

    _isConnecting = true;
    _isntConnected = false;
    notifyConnectionStateChanged();
    try {
      var connected = false;

      final cachedAddress = _cachedDeviceAddress;
      if (cachedAddress != null) {
        try {
          connected = await _connectToAddress(cachedAddress);
        } catch (_) {
          _cachedDeviceAddress = null;
        }
      }

      if (!connected) {
        await getDevices();
        _deviceConnected = null;
        for (final device in _devices) {
          if (device.name == specificDeviceName) {
            _deviceConnected = device;
            break;
          }
        }

        final matchedDevice = _deviceConnected;
        if (matchedDevice != null) {
          _cachedDeviceAddress = matchedDevice.address;
          connected = await _connectToAddress(matchedDevice.address);
        } else {
          _isntConnected = true;
        }
      }

      if (!connected) {
        _isntConnected = true;
      }
    } catch (_) {
      _isntConnected = true;
    } finally {
      _isConnecting = false;
      notifyConnectionStateChanged();
    }
  }

  void notifyConnectionStateChanged() {
    if (onConnectionStateChanged != null) {
      onConnectionStateChanged!(_connection != null && _connection!.isConnected,
          _isConnecting, _isntConnected);
    }
  }

  void initBluetoothState(Function(bool) callback) {
    _bluetooth.state.then((state) {
      _bluetoothState = state.isEnabled;
      callback(_bluetoothState);
    });

    _stateSubscription?.cancel();
    _stateSubscription = _bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BluetoothState.STATE_OFF:
          _bluetoothState = false;
          callback(_bluetoothState);
          break;
        case BluetoothState.STATE_ON:
          _bluetoothState = true;
          callback(_bluetoothState);
          break;
      }
    });
  }

  Future<void> dispose() async {
    await _stateSubscription?.cancel();
    _stateSubscription = null;
    await _connection?.close();
    _connection = null;
  }

  bool get isConnected => _connection?.isConnected ?? false;
  bool get isConnecting => _isConnecting;
  bool get bluetoothState => _bluetoothState;
}
