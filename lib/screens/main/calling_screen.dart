import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

class CallingScreen extends StatefulWidget {
  final String name;
  final String? orderCode;

  const CallingScreen({
    super.key,
    required this.name,
    this.orderCode,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  bool _isMuted = false;
  bool _isSpeaker = false;
  bool _isConnected = false;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isConnected = true);
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() => _seconds++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.2),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'R',
                        style: AppTypography.h1.copyWith(color: AppColors.primary, fontSize: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.name,
                    style: AppTypography.h1.copyWith(color: Colors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isConnected ? _formatDuration(_seconds) : 'Calling rider...',
                    style: AppTypography.bodyMedium.copyWith(color: _isConnected ? AppColors.primary : Colors.white70),
                  ),
                  if (widget.orderCode != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Order #${widget.orderCode}',
                      style: AppTypography.caption.copyWith(color: Colors.white54),
                    ),
                  ],
                ],
              ),
            ),

          
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: _isMuted ? Colors.white : Colors.white24,
                      foregroundColor: _isMuted ? Colors.black : Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                    icon: Icon(_isMuted ? Icons.mic_off_rounded : Icons.mic_rounded, size: 28),
                    onPressed: () => setState(() => _isMuted = !_isMuted),
                  ),

                
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(20),
                    ),
                    icon: const Icon(Icons.call_end_rounded, size: 36),
                    onPressed: () => Navigator.of(context).pop(),
                  ),

                  
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: _isSpeaker ? Colors.white : Colors.white24,
                      foregroundColor: _isSpeaker ? Colors.black : Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                    icon: Icon(_isSpeaker ? Icons.volume_up_rounded : Icons.volume_down_rounded, size: 28),
                    onPressed: () => setState(() => _isSpeaker = !_isSpeaker),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
