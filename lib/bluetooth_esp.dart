import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

import 'bluetooth.dart';

class BluetoothServiceESP {
  BluetoothServiceESP._internal();
  static final BluetoothServiceESP _instance = BluetoothServiceESP._internal();
  factory BluetoothServiceESP() => _instance;

  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  final BluetoothService _bluetoothService = BluetoothService();

  bool _bluetoothState = false;
  bool _isConnecting = false;
  bool _isntConnected = true;
  bool _permissionsRequested = false;
  BluetoothConnection? _connection;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _deviceConnected;
  String? _cachedDeviceAddress;
  final String specificDeviceName = "ESP32_HeadMotion";
  Function(bool, bool, bool)? onConnectionStateChanged;
  StreamSubscription<Uint8List>? _dataSubscription;
  StreamSubscription<BluetoothState>? _stateSubscription;

  void listenToData([Function(String)? onDataReceived]) {
    _dataSubscription?.cancel();
    final input = _connection?.input;
    if (input == null) return;

    _dataSubscription = input.listen((packet) {
      for (final byte in packet) {
        // Forward known control bytes to the wheelchair.
        if (byte == 108 || byte == 114 || byte == 102 || byte == 98 || byte == 115) {
          _bluetoothService.sendCommandCodeUnit(byte);
        }
        if (onDataReceived != null) {
          onDataReceived(String.fromCharCode(byte));
        }
      }
    });
  }

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
    await _dataSubscription?.cancel();
    _dataSubscription = null;
    await _stateSubscription?.cancel();
    _stateSubscription = null;
    await _connection?.close();
    _connection = null;
  }

  Future<void> stopListeningToData() async {
    await _dataSubscription?.cancel();
    _dataSubscription = null;
  }

  bool get isConnected => _connection?.isConnected ?? false;
  bool get isConnecting => _isConnecting;
  bool get bluetoothState => _bluetoothState;
}
