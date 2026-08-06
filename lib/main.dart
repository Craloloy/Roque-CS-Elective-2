import 'dart:convert';

import 'package:flutter/material.dart';

import 'niki_image.dart';

void main() {
  runApp(const CallApp());
}

enum CallStatus { incoming, connected, ended }

class CallApp extends StatelessWidget {
  const CallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Niki Call Screen',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F4F4),
      ),
      home: const CallScreen(),
    );
  }
}

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with SingleTickerProviderStateMixin {
  bool isMuted = false;
  bool isBluetoothOn = false;
  bool isOnHold = false;
  bool isSpeakerOn = false;
  CallStatus callStatus = CallStatus.incoming;

  late final AnimationController _pulseController;
  late final MemoryImage _nikiImage;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _nikiImage = MemoryImage(base64Decode(nikiImageBase64));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _statusText {
    switch (callStatus) {
      case CallStatus.incoming:
        return 'Incoming Call';
      case CallStatus.connected:
        return 'Connected';
      case CallStatus.ended:
        return 'Call Ended';
    }
  }

  void _handleMainCallButton() {
    setState(() {
      switch (callStatus) {
        case CallStatus.incoming:
          callStatus = CallStatus.connected;
          _pulseController.stop();
          break;
        case CallStatus.connected:
          callStatus = CallStatus.ended;
          _pulseController.stop();
          break;
        case CallStatus.ended:
          callStatus = CallStatus.incoming;
          _pulseController.repeat(reverse: true);
          break;
      }
    });
  }

  void _openKeypad() {
    if (callStatus == CallStatus.ended) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _KeypadSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = callStatus == CallStatus.connected;
    final isEnded = callStatus == CallStatus.ended;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Container(
              width: 360,
              constraints: const BoxConstraints(minHeight: 690),
              padding: const EdgeInsets.fromLTRB(30, 28, 30, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(42),
                border: Border.all(
                  color: const Color(0xFF29283F),
                  width: 11,
                ),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 18,
                    offset: Offset(0, 8),
                    color: Color(0x26000000),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _statusText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final pulse = _pulseController.value;
                      return SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _pulseCircle(
                              188 + (pulse * 8),
                              const Color(0x2038D9EA),
                            ),
                            _pulseCircle(
                              156 + (pulse * 6),
                              const Color(0x5035D9EA),
                            ),
                            _pulseCircle(
                              124 + (pulse * 4),
                              const Color(0xFF24C5DE),
                            ),
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                image: DecorationImage(
                                  image: _nikiImage,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Niki',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '+63 976 229 9449',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 44),
                  const Divider(color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CallOption(
                        icon: isMuted ? Icons.mic_off_outlined : Icons.mic_none,
                        label: 'Mute',
                        active: isMuted,
                        enabled: isConnected,
                        onTap: () => setState(() => isMuted = !isMuted),
                      ),
                      _CallOption(
                        icon: Icons.bluetooth,
                        label: 'Bluetooth',
                        active: isBluetoothOn,
                        enabled: isConnected,
                        onTap: () =>
                            setState(() => isBluetoothOn = !isBluetoothOn),
                      ),
                      _CallOption(
                        icon: Icons.phone_paused_outlined,
                        label: 'Hold',
                        active: isOnHold,
                        enabled: isConnected,
                        onTap: () => setState(() => isOnHold = !isOnHold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: 'Keypad',
                        onPressed: isEnded ? null : _openKeypad,
                        icon: const Icon(Icons.dialpad, size: 26),
                      ),
                      GestureDetector(
                        onTap: _handleMainCallButton,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected
                                ? const Color(0xFFE34B4B)
                                : const Color(0xFF14C9DF),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 10,
                                offset: Offset(0, 5),
                                color: Color(0x26000000),
                              ),
                            ],
                          ),
                          child: Icon(
                            isConnected ? Icons.call_end : Icons.call,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Speaker',
                        onPressed: isConnected
                            ? () => setState(
                                  () => isSpeakerOn = !isSpeakerOn,
                                )
                            : null,
                        icon: Icon(
                          isSpeakerOn
                              ? Icons.volume_up
                              : Icons.volume_down_outlined,
                          size: 28,
                          color: isSpeakerOn
                              ? const Color(0xFF14AFC4)
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pulseCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _CallOption extends StatelessWidget {
  const _CallOption({
    required this.icon,
    required this.label,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = enabled ? Colors.black54 : Colors.black26;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        child: Column(
          children: [
            Icon(
              icon,
              size: 27,
              color: active ? const Color(0xFF14AFC4) : inactiveColor,
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? const Color(0xFF14AFC4) : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeypadSheet extends StatefulWidget {
  const _KeypadSheet();

  @override
  State<_KeypadSheet> createState() => _KeypadSheetState();
}

class _KeypadSheetState extends State<_KeypadSheet> {
  String enteredNumber = '';

  void _onKeyTap(String key) {
    setState(() => enteredNumber += key);
  }

  void _deleteLastDigit() {
    if (enteredNumber.isEmpty) return;
    setState(() {
      enteredNumber = enteredNumber.substring(0, enteredNumber.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    const keys = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '*', '0', '#',
    ];

    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = (screenHeight * 0.82).clamp(480.0, 680.0);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: sheetHeight,
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 640),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
        decoration: const BoxDecoration(
          color: Color(0xFFF7F6FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      enteredNumber.isEmpty ? 'Tap numbers here' : enteredNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        color: enteredNumber.isEmpty
                            ? Colors.black45
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: _deleteLastDigit,
                  icon: const Icon(Icons.backspace_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final availableHeight = constraints.maxHeight;
                  final keyWidth = (availableWidth - 32) / 3;
                  final keyHeight = (availableHeight - 30) / 4;
                  final keySize = keyWidth < keyHeight ? keyWidth : keyHeight;

                  return GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: keys.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 16,
                      mainAxisExtent: keySize,
                    ),
                    itemBuilder: (context, index) {
                      return Center(
                        child: SizedBox.square(
                          dimension: keySize,
                          child: Material(
                            color: const Color(0xFFEFEFF0),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _onKeyTap(keys[index]),
                              child: Center(
                                child: Text(
                                  keys[index],
                                  style: const TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
