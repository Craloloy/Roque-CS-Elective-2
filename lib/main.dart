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
        scaffoldBackgroundColor: Colors.white,
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
  bool showKeypad = false;
  String enteredNumber = '';
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
          showKeypad = false;
          enteredNumber = '';
          _pulseController.stop();
          break;
        case CallStatus.ended:
          callStatus = CallStatus.incoming;
          _pulseController.repeat(reverse: true);
          break;
      }
    });
  }

  void _toggleKeypad() {
    if (callStatus == CallStatus.ended) return;
    setState(() => showKeypad = !showKeypad);
  }

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
    final isConnected = callStatus == CallStatus.connected;
    final isEnded = callStatus == CallStatus.ended;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isShortScreen = constraints.maxHeight < 720;
            final keypadVisible = showKeypad && !isEnded;
            final avatarArea = keypadVisible
                ? (isShortScreen ? 108.0 : 122.0)
                : (isShortScreen ? 170.0 : 210.0);
            final outerRing = keypadVisible
                ? (isShortScreen ? 102.0 : 116.0)
                : (isShortScreen ? 160.0 : 190.0);
            final middleRing = keypadVisible
                ? (isShortScreen ? 84.0 : 96.0)
                : (isShortScreen ? 132.0 : 156.0);
            final innerRing = keypadVisible
                ? (isShortScreen ? 68.0 : 78.0)
                : (isShortScreen ? 106.0 : 124.0);
            final photoSize = keypadVisible
                ? (isShortScreen ? 50.0 : 58.0)
                : (isShortScreen ? 78.0 : 92.0);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                28,
                keypadVisible ? 12 : 24,
                28,
                14,
              ),
              child: Column(
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    child: Column(
                      children: [
                        Text(
                          _statusText,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: keypadVisible ? 8 : 22),
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final pulse = _pulseController.value;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              width: avatarArea,
                              height: avatarArea,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  _pulseCircle(
                                    outerRing + (pulse * 8),
                                    const Color(0x2038D9EA),
                                  ),
                                  _pulseCircle(
                                    middleRing + (pulse * 6),
                                    const Color(0x5035D9EA),
                                  ),
                                  _pulseCircle(
                                    innerRing + (pulse * 4),
                                    const Color(0xFF24C5DE),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 260),
                                    width: photoSize,
                                    height: photoSize,
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
                        SizedBox(height: keypadVisible ? 8 : 20),
                        const Text(
                          'Niki',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          keypadVisible && enteredNumber.isNotEmpty
                              ? enteredNumber
                              : '+63 976 229 9449',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: keypadVisible ? 22 : 18,
                            fontWeight: keypadVisible && enteredNumber.isNotEmpty
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: keypadVisible ? 12 : 0),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.08),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: keypadVisible
                          ? _InlineKeypad(
                              key: const ValueKey('keypad'),
                              enteredNumber: enteredNumber,
                              onKeyTap: _onKeyTap,
                              onDelete: _deleteLastDigit,
                              onClose: _toggleKeypad,
                            )
                          : _CallControls(
                              key: const ValueKey('controls'),
                              isConnected: isConnected,
                              isEnded: isEnded,
                              isMuted: isMuted,
                              isBluetoothOn: isBluetoothOn,
                              isOnHold: isOnHold,
                              isSpeakerOn: isSpeakerOn,
                              onMute: () =>
                                  setState(() => isMuted = !isMuted),
                              onBluetooth: () => setState(
                                () => isBluetoothOn = !isBluetoothOn,
                              ),
                              onHold: () =>
                                  setState(() => isOnHold = !isOnHold),
                              onKeypad: _toggleKeypad,
                              onCall: _handleMainCallButton,
                              onSpeaker: () => setState(
                                () => isSpeakerOn = !isSpeakerOn,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _pulseCircle(double size, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _CallControls extends StatelessWidget {
  const _CallControls({
    super.key,
    required this.isConnected,
    required this.isEnded,
    required this.isMuted,
    required this.isBluetoothOn,
    required this.isOnHold,
    required this.isSpeakerOn,
    required this.onMute,
    required this.onBluetooth,
    required this.onHold,
    required this.onKeypad,
    required this.onCall,
    required this.onSpeaker,
  });

  final bool isConnected;
  final bool isEnded;
  final bool isMuted;
  final bool isBluetoothOn;
  final bool isOnHold;
  final bool isSpeakerOn;
  final VoidCallback onMute;
  final VoidCallback onBluetooth;
  final VoidCallback onHold;
  final VoidCallback onKeypad;
  final VoidCallback onCall;
  final VoidCallback onSpeaker;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        const Divider(color: Color(0xFFE0E0E0)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _CallOption(
              icon: isMuted ? Icons.mic_off_outlined : Icons.mic_none,
              label: 'Mute',
              active: isMuted,
              enabled: isConnected,
              onTap: onMute,
            ),
            _CallOption(
              icon: Icons.bluetooth,
              label: 'Bluetooth',
              active: isBluetoothOn,
              enabled: isConnected,
              onTap: onBluetooth,
            ),
            _CallOption(
              icon: Icons.phone_paused_outlined,
              label: 'Hold',
              active: isOnHold,
              enabled: isConnected,
              onTap: onHold,
            ),
          ],
        ),
        const SizedBox(height: 34),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              tooltip: 'Keypad',
              onPressed: isEnded ? null : onKeypad,
              icon: const Icon(Icons.dialpad, size: 30),
            ),
            GestureDetector(
              onTap: onCall,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected
                      ? const Color(0xFFE34B4B)
                      : const Color(0xFF14C9DF),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 12,
                      offset: Offset(0, 5),
                      color: Color(0x26000000),
                    ),
                  ],
                ),
                child: Icon(
                  isConnected ? Icons.call_end : Icons.call,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Speaker',
              onPressed: isConnected ? onSpeaker : null,
              icon: Icon(
                isSpeakerOn ? Icons.volume_up : Icons.volume_down_outlined,
                size: 30,
                color: isSpeakerOn ? const Color(0xFF14AFC4) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _InlineKeypad extends StatelessWidget {
  const _InlineKeypad({
    super.key,
    required this.enteredNumber,
    required this.onKeyTap,
    required this.onDelete,
    required this.onClose,
  });

  final String enteredNumber;
  final ValueChanged<String> onKeyTap;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    const keys = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '*', '0', '#',
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Delete',
              onPressed: enteredNumber.isEmpty ? null : onDelete,
              icon: const Icon(Icons.backspace_outlined),
            ),
            IconButton(
              tooltip: 'Close keypad',
              onPressed: onClose,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
            ),
          ],
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final keyWidth = (constraints.maxWidth - 28) / 3;
              final keyHeight = (constraints.maxHeight - 24) / 4;
              final keySize = keyWidth < keyHeight ? keyWidth : keyHeight;

              return GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: keys.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 8,
                  mainAxisExtent: keySize,
                ),
                itemBuilder: (context, index) {
                  return Center(
                    child: SizedBox.square(
                      dimension: keySize,
                      child: Material(
                        color: const Color(0xFFF0F0F2),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => onKeyTap(keys[index]),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
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
