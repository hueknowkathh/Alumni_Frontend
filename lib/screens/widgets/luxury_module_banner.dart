import 'package:flutter/material.dart';

class LuxuryBannerAction {
  const LuxuryBannerAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.busyLabel,
    this.enabled = true,
    this.iconOnly = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final String? busyLabel;
  final bool enabled;
  final bool iconOnly;
}

class LuxuryModuleBanner extends StatelessWidget {
  const LuxuryModuleBanner({
    super.key,
    this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    this.chips = const [],
    this.trailing = const [],
    this.actions = const [],
    this.compact = false,
  });

  final String? eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final List<Widget> chips;
  final List<Widget> trailing;
  final List<LuxuryBannerAction> actions;
  final bool compact;

  static const Color _maroon = Color(0xFF4A152C);
  static const Color _plum = Color(0xFF6A2A43);
  static const Color _wine = Color(0xFF35101E);
  static const Color _gold = Color(0xFFC5A046);
  static const Color _softGold = Color(0xFFF4D88A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 20 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_maroon, _plum, _wine],
          stops: [0.0, 0.55, 1.0],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: _maroon.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -36,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _gold.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: -24,
            bottom: -58,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          compact ? _buildCompact() : _buildWide(),
        ],
      ),
    );
  }

  Widget _buildCompact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((eyebrow ?? '').trim().isNotEmpty) ...[
          _buildEyebrow(),
          const SizedBox(height: 16),
        ],
        _buildIconTile(68),
        const SizedBox(height: 16),
        _buildHeading(26),
        const SizedBox(height: 10),
        _buildDescription(),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12, children: chips),
        ],
        if (trailing.isNotEmpty || actions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ...trailing,
              ...actions.map(_buildAction),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildWide() {
    final hasActions = trailing.isNotEmpty || actions.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: hasActions ? 5 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((eyebrow ?? '').trim().isNotEmpty) ...[
                _buildEyebrow(),
                const SizedBox(height: 16),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIconTile(74),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeading(32),
                        const SizedBox(height: 10),
                        _buildDescription(),
                      ],
                    ),
                  ),
                ],
              ),
              if (chips.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(spacing: 12, runSpacing: 12, children: chips),
              ],
            ],
          ),
        ),
        if (hasActions) ...[
          const SizedBox(width: 24),
          Flexible(
            flex: 3,
            child: Align(
              alignment: Alignment.topRight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final actionWidgets = [
                    ...trailing,
                    ...actions.map(_buildAction),
                  ];

                  if (constraints.maxWidth >= 440 &&
                      actionWidgets.length <= 2) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < actionWidgets.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          actionWidgets[i],
                        ],
                      ],
                    );
                  }

                  return Align(
                    alignment: Alignment.topRight,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: actionWidgets,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEyebrow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Text(
        eyebrow ?? '',
        style: const TextStyle(
          color: _softGold,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.75,
        ),
      ),
    );
  }

  Widget _buildIconTile(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.30),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: _gold, size: size * 0.48),
    );
  }

  Widget _buildHeading(double size) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.08,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      description,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.82),
        height: 1.5,
      ),
    );
  }

  Widget _buildAction(LuxuryBannerAction action) {
    if (action.iconOnly) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action.enabled ? action.onPressed : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              action.icon,
              size: 22,
              color: action.enabled
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.38),
            ),
          ),
        ),
      );
    }

    if (action.filled) {
      return FilledButton.icon(
        onPressed: action.enabled ? action.onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: _maroon,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(action.icon),
        label: Text(action.label),
      );
    }

    return FilledButton.icon(
      onPressed: action.enabled ? action.onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _maroon,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(action.icon),
      label: Text(action.label),
    );
  }
}
