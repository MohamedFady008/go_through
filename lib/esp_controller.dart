import 'package:flutter/material.dart';
import 'bluetooth.dart';
import 'bluetooth_esp.dart';

class ESPController extends StatefulWidget {
  const ESPController({super.key});

  @override
  State<ESPController> createState() => _ESPControllerState();
}

class _ESPControllerState extends State<ESPController> {
  final BluetoothServiceESP _bluetoothServiceESP = BluetoothServiceESP();
  final BluetoothService _bluetoothService = BluetoothService();
  bool _isConnected = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _bluetoothServiceESP.requestPermission();
    _bluetoothService.requestPermission();
  }

  Future<void> _connectToESP() async {
    if (_isConnected || _isConnecting) return;
    setState(() {
      _isConnecting = true;
    });

    try {
      await Future.wait([
        _bluetoothServiceESP.connectToDeviceByName(),
        _bluetoothService.connectToDeviceByName(),
      ]);
      _bluetoothServiceESP.listenToData();
    } catch (_) {
      // Keep state update below; failed connect simply leaves _isConnected false.
    }

    if (!mounted) return;
    setState(() {
      _isConnected =
          _bluetoothServiceESP.isConnected && _bluetoothService.isConnected;
      _isConnecting = false;
    });
  }

  @override
  void dispose() {
    _bluetoothServiceESP.stopListeningToData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _isConnected
        ? 'ESP32 Linked'
        : (_isConnecting ? 'Connecting...' : 'Connect ESP32');

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isConnected || _isConnecting ? null : _connectToESP,
        icon: Icon(_isConnected ? Icons.check_circle : Icons.sensors_rounded),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
