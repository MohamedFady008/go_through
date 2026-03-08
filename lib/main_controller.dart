import 'dart:math';
import 'package:flutter/material.dart';
import 'arc_painter.dart';
import 'bluetooth.dart';

class MainController extends StatefulWidget {
  const MainController({super.key});

  @override
  State<MainController> createState() => _MainControllerState();
}

class _MainControllerState extends State<MainController> {
  final BluetoothService _bluetoothService = BluetoothService();
  String? _activeCommand;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isntConnected = true;

  @override
  void initState() {
    super.initState();
    _bluetoothService.requestPermission();
    _bluetoothService.initBluetoothState((state) {});
    _bluetoothService.onConnectionStateChanged =
        (isConnected, isConnecting, isntConnected) {
      if (!mounted) return;
      if (_isConnected == isConnected &&
          _isConnecting == isConnecting &&
          _isntConnected == isntConnected) {
        return;
      }
      setState(() {
        _isConnected = isConnected;
        _isConnecting = isConnecting;
        _isntConnected = isntConnected;
      });
    };
  }

  @override
  void dispose() {
    _activeCommand = null;
    _bluetoothService.onConnectionStateChanged = null;
    super.dispose();
  }

  Color _getBluetoothButtonColor() {
    if (_isConnecting) {
      return const Color(0xFF2563EB);
    } else if (_isConnected) {
      return const Color(0xFF0E9F6E);
    } else if (_isntConnected) {
      return const Color(0xFFDC2626);
    }
    return const Color(0xFF334155);
  }

  String _connectionLabel() {
    if (_isConnecting) return 'Connecting';
    if (_isConnected) return 'Connected';
    return 'Connect';
  }

  Widget _buildArcVisual({
    required String command,
    required double innerRadius,
    required double outerRadius,
    required double startAngle,
    required Color color,
    required IconData icon,
    required double size,
  }) {
    final isActive = _activeCommand == command;
    final fillColor = isActive
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.18), color)
        : color;

    return RepaintBoundary(
      child: CustomPaint(
        size: Size(size, size),
        painter: ArcPainter(
          innerRadius: innerRadius,
          outerRadius: outerRadius,
          startAngle: startAngle,
          sweepAngle: pi / 2,
          color: fillColor,
          iconColor: Colors.white,
          strokeWidth: isActive ? 2.8 : 1.6,
          icon: icon,
        ),
      ),
    );
  }

  String? _resolveCommandFromPosition(
    Offset localPosition,
    double size,
    double innerRadius,
    double outerRadius,
  ) {
    final center = Offset(size / 2, size / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final radius = sqrt(dx * dx + dy * dy);

    if (radius < innerRadius || radius > outerRadius) {
      return null;
    }

    var angle = atan2(dy, dx);
    if (angle < 0) {
      angle += 2 * pi;
    }

    if (angle >= 5 * pi / 4 && angle < 7 * pi / 4) return 'f';
    if (angle >= pi / 4 && angle < 3 * pi / 4) return 'b';
    if (angle >= 3 * pi / 4 && angle < 5 * pi / 4) return 'l';
    if (angle >= 7 * pi / 4 || angle < pi / 4) return 'r';
    return null;
  }

  void _sendStopIfNeeded() {
    if (_activeCommand != null) {
      _activeCommand = null;
      _bluetoothService.sendData('s');
    }
  }

  void _handlePointer(
    Offset localPosition,
    double size,
    double innerRadius,
    double outerRadius,
  ) {
    final command = _resolveCommandFromPosition(
      localPosition,
      size,
      innerRadius,
      outerRadius,
    );
    if (command == _activeCommand) return;

    if (command == null) {
      _sendStopIfNeeded();
      return;
    }

    _activeCommand = command;
    _bluetoothService.sendData(command);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final controllerSize = min(screenWidth * 0.78, 320.0);
    final outerRadius = controllerSize / 2;
    final innerRadius = outerRadius / 2;
    final centerButtonSize = controllerSize * 0.43;

    return SizedBox(
      width: controllerSize,
      height: controllerSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
            stops: [0.25, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) => _handlePointer(
            event.localPosition,
            controllerSize,
            innerRadius,
            outerRadius,
          ),
          onPointerMove: (event) => _handlePointer(
            event.localPosition,
            controllerSize,
            innerRadius,
            outerRadius,
          ),
          onPointerUp: (_) => _sendStopIfNeeded(),
          onPointerCancel: (_) => _sendStopIfNeeded(),
          child: Stack(
            children: [
              _buildArcVisual(
                command: 'f',
                innerRadius: innerRadius,
                outerRadius: outerRadius,
                startAngle: 5 * pi / 4,
                color: const Color(0xFF0E9F6E),
                icon: Icons.keyboard_arrow_up_rounded,
                size: controllerSize,
              ),
              _buildArcVisual(
                command: 'b',
                innerRadius: innerRadius,
                outerRadius: outerRadius,
                startAngle: pi / 4,
                color: const Color(0xFFF59E0B),
                icon: Icons.keyboard_arrow_down_rounded,
                size: controllerSize,
              ),
              _buildArcVisual(
                command: 'r',
                innerRadius: innerRadius,
                outerRadius: outerRadius,
                startAngle: -pi / 4,
                color: const Color(0xFF2563EB),
                icon: Icons.keyboard_arrow_right_rounded,
                size: controllerSize,
              ),
              _buildArcVisual(
                command: 'l',
                innerRadius: innerRadius,
                outerRadius: outerRadius,
                startAngle: 3 * pi / 4,
                color: const Color(0xFF0EA5E9),
                icon: Icons.keyboard_arrow_left_rounded,
                size: controllerSize,
              ),
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: _bluetoothService.connectToDeviceByName,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    width: centerButtonSize,
                    height: centerButtonSize,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.alphaBlend(
                            Colors.white.withValues(alpha: 0.12),
                            _getBluetoothButtonColor(),
                          ),
                          _getBluetoothButtonColor(),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getBluetoothButtonColor().withValues(
                            alpha: 0.34,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bluetooth_rounded,
                          size: 38.0,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _connectionLabel(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
