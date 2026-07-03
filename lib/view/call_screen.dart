import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agroa_videocall/features/broadcast/application/broadcast_notifier.dart';
import 'package:agroa_videocall/features/broadcast/domain/models/broadcast_state.dart';
import 'package:agroa_videocall/services/agora_engine_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CallScreen extends StatelessWidget {
  final String channelName;
  final ClientRoleType userRole;
  final AgoraEngineService? agoraService;

  const CallScreen({
    super.key,
    required this.channelName,
    required this.userRole,
    this.agoraService,
  });

  @override
  Widget build(BuildContext context) {
    final content = _CallScreenContent(
      channelName: channelName,
      userRole: userRole,
    );

    if (agoraService != null) {
      return ProviderScope(
        overrides: [
          agoraEngineServiceProvider.overrideWithValue(agoraService!),
        ],
        child: content,
      );
    }
    return content;
  }
}

class _CallScreenContent extends ConsumerStatefulWidget {
  final String channelName;
  final ClientRoleType userRole;

  const _CallScreenContent({
    required this.channelName,
    required this.userRole,
  });

  @override
  ConsumerState<_CallScreenContent> createState() => _CallScreenContentState();
}

class _CallScreenContentState extends ConsumerState<_CallScreenContent>
    with SingleTickerProviderStateMixin {
  bool _controlsVisible = true;
  Timer? _controlsTimer;
  late AnimationController _controlsAnimController;
  late Animation<double> _controlsOpacity;

  @override
  void initState() {
    super.initState();
    _controlsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _controlsOpacity = CurvedAnimation(
      parent: _controlsAnimController,
      curve: Curves.easeInOut,
    );

    _resetControlsTimer();

    // Start Agora join flow after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(broadcastNotifierProvider.notifier).join(
              channelId: widget.channelName,
              role: widget.userRole,
            );
      }
    });
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controlsAnimController.dispose();
    super.dispose();
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _controlsVisible = false);
        _controlsAnimController.reverse();
      }
    });
  }

  void _toggleControlsVisibility() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) {
      _controlsAnimController.forward();
      _resetControlsTimer();
    } else {
      _controlsAnimController.reverse();
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final broadcastState = ref.watch(broadcastNotifierProvider);

    // Listen for error states to trigger SnackBars
    ref.listen<BroadcastState>(broadcastNotifierProvider, (previous, next) {
      if (next is BroadcastError) {
        _showSnackBar(next.message);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Column(
          children: [
            Text(
              widget.channelName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildLiveBadge(),
          ],
        ),
        leading: IconButton(
          key: const Key('backButton'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: _toggleControlsVisibility,
        child: Stack(
          children: [
            _buildVideoView(broadcastState),
            _buildGradientOverlay(),
            if (widget.userRole == ClientRoleType.clientRoleBroadcaster)
              _buildControlsPanel(colorScheme, broadcastState),
            if (widget.userRole == ClientRoleType.clientRoleAudience)
              _buildAudienceOverlay(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      key: const Key('liveBadge'),
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildVideoView(BroadcastState broadcastState) {
    if (broadcastState is! BroadcastConnected) {
      return const Center(
        key: Key('connectingView'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
                key: Key('loadingIndicator'), color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Connecting...',
              key: Key('connectingText'),
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final rawEngine = ref.read(agoraEngineServiceProvider).rawEngine;
    final List<Widget> videoWidgets = [];

    if (widget.userRole == ClientRoleType.clientRoleBroadcaster &&
        rawEngine != null) {
      videoWidgets.add(
        AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: rawEngine,
            canvas: const VideoCanvas(uid: 0),
          ),
        ),
      );
    }

    for (final uid in broadcastState.remoteUids) {
      if (rawEngine != null) {
        videoWidgets.add(
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: rawEngine,
              canvas: VideoCanvas(uid: uid),
              connection: RtcConnection(channelId: widget.channelName),
            ),
          ),
        );
      }
    }

    if (videoWidgets.isEmpty) {
      return Center(
        key: const Key('waitingView'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_rounded,
                color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Waiting for participants...',
              key: Key('waitingText'),
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (videoWidgets.length == 1) {
      return videoWidgets.first;
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: videoWidgets.length <= 2 ? 1 : 2,
        childAspectRatio: 9 / 16,
      ),
      itemCount: videoWidgets.length,
      itemBuilder: (context, index) => videoWidgets[index],
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(153),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withAlpha(179),
              ],
              stops: const [0.0, 0.2, 0.7, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsPanel(ColorScheme colorScheme, BroadcastState state) {
    final bool audioMuted = state is BroadcastConnected ? state.audioMuted : false;
    final bool videoMuted = state is BroadcastConnected ? state.videoMuted : false;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _controlsOpacity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  key: const Key('muteButton'),
                  icon: audioMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  label: audioMuted ? 'Unmute' : 'Mute',
                  isActive: audioMuted,
                  color: audioMuted ? Colors.red : Colors.white,
                  onPressed: () {
                    ref.read(broadcastNotifierProvider.notifier).toggleAudio();
                    _resetControlsTimer();
                  },
                ),
                _buildEndCallButton(),
                _buildControlButton(
                  key: const Key('cameraButton'),
                  icon: videoMuted
                      ? Icons.videocam_off_rounded
                      : Icons.videocam_rounded,
                  label: videoMuted ? 'Show' : 'Hide',
                  isActive: videoMuted,
                  color: videoMuted ? Colors.red : Colors.white,
                  onPressed: () {
                    ref.read(broadcastNotifierProvider.notifier).toggleVideo();
                    _resetControlsTimer();
                  },
                ),
                _buildControlButton(
                  key: const Key('switchCameraButton'),
                  icon: Icons.cameraswitch_rounded,
                  label: 'Flip',
                  isActive: false,
                  color: Colors.white,
                  onPressed: () {
                    ref.read(broadcastNotifierProvider.notifier).switchCamera();
                    _resetControlsTimer();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required Key key,
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          key: key,
          color: isActive
              ? Colors.red.withAlpha(51)
              : Colors.white.withAlpha(51),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(icon, color: color, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildEndCallButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          key: const Key('endCallButton'),
          color: Colors.red,
          shape: const CircleBorder(),
          elevation: 6,
          child: InkWell(
            onTap: () {
              ref.read(broadcastNotifierProvider.notifier).leave();
              Navigator.of(context).pop();
            },
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child:
                  Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'End',
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildAudienceOverlay(ColorScheme colorScheme) {
    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: Container(
            key: const Key('audienceOverlay'),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(128),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_rounded,
                    color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Text(
                  'Watching live',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
