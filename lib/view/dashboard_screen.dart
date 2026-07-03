import 'dart:developer';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:go_router/go_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _channelController = TextEditingController();
  bool _validateError = false;
  ClientRoleType _currentRole = ClientRoleType.clientRoleBroadcaster;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _channelController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Broadcast'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              _buildHeroSection(colorScheme, textTheme),
              const SizedBox(height: 32),
              _buildChannelInputCard(colorScheme, textTheme),
              const SizedBox(height: 20),
              _buildRoleSelectionCard(colorScheme, textTheme),
              const SizedBox(height: 32),
              _buildConnectButton(colorScheme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withAlpha(77),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.broadcast_on_personal_rounded,
            size: 52,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Go Live',
          style: textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start or join a live broadcast session',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildChannelInputCard(
      ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.meeting_room_rounded,
                    color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Channel',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('channelNameField'),
              controller: _channelController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_validateError) {
                  setState(() => _validateError = false);
                }
              },
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.videocam_rounded,
                  color: colorScheme.primary,
                ),
                errorText: _validateError ? 'Channel name is required' : null,
                labelText: 'Channel Name',
                hintText: 'e.g. my_live_stream',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelectionCard(
      ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_alt_rounded,
                    color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Your Role',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRoleTile(
              key: const Key('broadcasterRadio'),
              icon: Icons.videocam_rounded,
              title: 'Broadcaster',
              subtitle: 'Stream video & audio to your audience',
              value: ClientRoleType.clientRoleBroadcaster,
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
            const Divider(height: 8, indent: 16, endIndent: 16),
            _buildRoleTile(
              key: const Key('audienceRadio'),
              icon: Icons.visibility_rounded,
              title: 'Audience',
              subtitle: 'Watch and listen to the broadcast',
              value: ClientRoleType.clientRoleAudience,
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTile({
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
    required ClientRoleType value,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final isSelected = _currentRole == value;
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _currentRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withAlpha(128)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // ignore: deprecated_member_use
            Radio<ClientRoleType>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: _currentRole,
              // ignore: deprecated_member_use
              onChanged: (v) => setState(() => _currentRole = v!),
              activeColor: colorScheme.primary,
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectButton(ColorScheme colorScheme) {
    return FilledButton.icon(
      key: const Key('connectButton'),
      onPressed: _joinChannel,
      icon: const Icon(Icons.video_camera_front_rounded, size: 22),
      label: const Text(
        'Join Channel',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  Future<void> _joinChannel() async {
    final channelText = _channelController.text.trim();
    setState(() {
      _validateError = channelText.isEmpty;
    });

    if (channelText.isEmpty) return;

    await _handleCameraAndMicPermission();

    if (!mounted) return;

    context.push(
      '/call?channelName=${Uri.encodeComponent(channelText)}&roleIndex=${_currentRole.index}',
    );
  }

  Future<void> _handleCameraAndMicPermission() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();
    log('Camera: ${statuses[Permission.camera]}');
    log('Microphone: ${statuses[Permission.microphone]}');
  }
}
