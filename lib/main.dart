import 'package:flutter/material.dart';

void main() {
  runApp(const CallApp());
}

class CallApp extends StatelessWidget {
  const CallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dialing Screen',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F4F4),
        fontFamily: 'Arial',
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
  bool callEnded = false;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleKeypad() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _KeypadSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    callEnded ? 'Call Ended' : 'Dialing',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final pulse = _pulseController.value;
                      return SizedBox(
                        width: 190,
                        height: 190,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _pulseCircle(
                              180 + (pulse * 8),
                              const Color(0x2038D9EA),
                            ),
                            _pulseCircle(
                              148 + (pulse * 6),
                              const Color(0x5035D9EA),
                            ),
                            _pulseCircle(
                              118 + (pulse * 4),
                              const Color(0xFF24C5DE),
                            ),
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF72DDEA),
                                    Color(0xFF116E83),
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'PL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 27,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Pearl Luna',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '+ 476-229-9449',
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
                        onTap: () => setState(() => isMuted = !isMuted),
                      ),
                      _CallOption(
                        icon: Icons.bluetooth,
                        label: 'Bluetooth',
                        active: isBluetoothOn,
                        onTap: () =>
                            setState(() => isBluetoothOn = !isBluetoothOn),
                      ),
                      _CallOption(
                        icon: Icons.phone_paused_outlined,
                        label: 'Hold',
                        active: isOnHold,
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
                        onPressed: _toggleKeypad,
                        icon: const Icon(Icons.dialpad, size: 26),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => callEnded = !callEnded);
                          if (callEnded) {
                            _pulseController.stop();
                          } else {
                            _pulseController.repeat(reverse: true);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: callEnded
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
                            callEnded ? Icons.call_end : Icons.call,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Speaker',
                        onPressed: () =>
                            setState(() => isSpeakerOn = !isSpeakerOn),
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        child: Column(
          children: [
            Icon(
              icon,
              size: 27,
              color: active ? const Color(0xFF14AFC4) : Colors.black54,
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? const Color(0xFF14AFC4) : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeypadSheet extends StatelessWidget {
  const _KeypadSheet();

  @override
  Widget build(BuildContext context) {
    const keys = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '*', '0', '#',
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(34, 8, 34, 30),
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: keys.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 18,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            return InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: () {},
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF0F0F0),
                ),
                alignment: Alignment.center,
                child: Text(
                  keys[index],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
