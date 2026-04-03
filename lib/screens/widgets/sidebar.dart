import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class Sidebar extends StatefulWidget {
  final String role;
  final int selectedIndex;
  final Function(int)? onItemSelected;
  final Future<void> Function()? onBeforeLogout;
  final bool isCollapsed;
  final VoidCallback? onToggleSidebar;
  final bool isInDrawer;

  const Sidebar({
    super.key,
    required this.role,
    this.selectedIndex = 0,
    this.onItemSelected,
    this.onBeforeLogout,
    this.isCollapsed = false,
    this.onToggleSidebar,
    this.isInDrawer = false,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  late bool _isCollapsed;

  static const Color _sidebarBg = Color(0xFF4A152C);
  static const Color _sidebarDeep = Color(0xFF32111F);
  static const Color _activeGold = Color(0xFFC5A046);
  static const Color _panelRose = Color(0xFF6A2A43);
  static const Color _panelPlum = Color(0xFF7A3751);
  static const Color _softText = Color(0xFFE9D8DF);

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.isCollapsed;
  }

  @override
  void didUpdateWidget(covariant Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isCollapsed = widget.isCollapsed;
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = _getMenuItems(widget.role);
    final sidebarWidth = _isCollapsed ? 88.0 : 292.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: sidebarWidth,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5A1832),
            Color(0xFF4A152C),
            Color(0xFF431226),
            Color(0xFF35101E),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.28, 0.68, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(6, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeroPanel(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                _isCollapsed ? 10 : 10,
                10,
                _isCollapsed ? 10 : 12,
                12,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < menuItems.length; i++)
                    _buildMenuTile(
                      context,
                      title: menuItems[i]['title'] as String,
                      icon: menuItems[i]['icon'] as IconData,
                      index: i,
                      isActive: i == widget.selectedIndex,
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isCollapsed ? 8 : 10,
                      vertical: 12,
                    ),
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.14),
                      height: 1,
                    ),
                  ),
                  _buildMenuTile(
                    context,
                    title: 'Logout',
                    icon: Icons.logout_rounded,
                    index: -1,
                    isLogout: true,
                  ),
                ],
              ),
            ),
          ),
          _buildFooterCard(),
        ],
      ),
    );
  }

  Widget _buildHeroPanel() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        _isCollapsed ? 10 : 16,
        22,
        _isCollapsed ? 10 : 16,
        18,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6E203E),
            Color(0xFF5A1832),
            Color(0xFF461426),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useCompactExpandedHeader =
              !_isCollapsed && constraints.maxWidth < 210;

          if (_isCollapsed) {
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.10),
                        Colors.white.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Tooltip(
                        message: _getRoleHeader(widget.role),
                        child: _buildLogo(size: 50),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 34,
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  width: double.infinity,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: useCompactExpandedHeader ? 14 : 16,
                  vertical: useCompactExpandedHeader ? 14 : 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    colors: [_panelPlum, _panelRose, Color(0xFF5E233A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 20,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildLogo(size: useCompactExpandedHeader ? 56 : 66),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildRoleHeaderText(
                              _getRoleHeader(widget.role),
                              compact: useCompactExpandedHeader,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                width: double.infinity,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogo({required double size}) {
    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: EdgeInsets.all(size * 0.02),
        child: Image.asset('assets/jmclogo.png', fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildRoleHeaderText(String text, {required bool compact}) {
    final displayText = text.toUpperCase();
    return Container(
      constraints: BoxConstraints(
        minHeight: compact ? 42 : 46,
        maxWidth: compact ? 136 : 168,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 18,
        vertical: compact ? 8 : 9,
      ),
      decoration: BoxDecoration(
        color: _activeGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _activeGold.withValues(alpha: 0.24)),
      ),
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFE3A1), Color(0xFFCDA14A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              displayText,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 15.5 : 17,
                fontWeight: FontWeight.w800,
                letterSpacing: compact ? 0.8 : 1.0,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getRoleHeader(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'dean':
        return 'Department Dean';
      case 'alumni':
        return 'Alumni';
      default:
        return role.toUpperCase();
    }
  }

  Widget _buildFooterCard() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _isCollapsed ? 10 : 12,
        0,
        _isCollapsed ? 10 : 12,
        12,
      ),
      child: Tooltip(
        message: 'Academic Year 2025-2026',
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(_isCollapsed ? 10 : 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: _isCollapsed
              ? const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.white70,
                  size: 18,
                )
              : const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Academic Year',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '2025-2026',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required int index,
    bool isActive = false,
    bool isLogout = false,
  }) {
    final tile = Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? _activeGold.withValues(alpha: 0.20)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? Border.all(color: Colors.white.withValues(alpha: 0.10))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            if (isLogout) {
              await widget.onBeforeLogout?.call();
              if (!mounted) return;
              await AuthService.logout(context);
              return;
            }
            if (widget.onItemSelected != null && index >= 0) {
              widget.onItemSelected!(index);
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _isCollapsed ? 0 : 14,
              vertical: 13,
            ),
            child: _isCollapsed
                ? Center(
                    child: Icon(
                      icon,
                      color: isActive ? Colors.white : Colors.white70,
                      size: 24,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        icon,
                        color: isActive ? Colors.white : Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.white70,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      if (isActive)
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );

    if (_isCollapsed) {
      return Tooltip(message: title, child: tile);
    }
    return tile;
  }

  List<Map<String, dynamic>> _getMenuItems(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return [
          {'title': 'Dashboard', 'icon': Icons.grid_view_outlined},
          {'title': 'Alumni List', 'icon': Icons.people_outline},
          {'title': 'Tracer Governance', 'icon': Icons.analytics_outlined},
          {'title': 'Verify Users', 'icon': Icons.verified_user_outlined},
          {'title': 'Announcements', 'icon': Icons.campaign_outlined},
          {'title': 'Jobs', 'icon': Icons.work_outline},
          {'title': 'Settings', 'icon': Icons.settings_outlined},
        ];
      case 'dean':
        return [
          {'title': 'Dashboard', 'icon': Icons.grid_view_outlined},
          {'title': 'Department Alumni', 'icon': Icons.people_outline},
          {'title': 'Career Reports', 'icon': Icons.work_outline},
          {'title': 'Career Overview', 'icon': Icons.analytics_outlined},
          {'title': 'Announcements', 'icon': Icons.campaign_outlined},
          {'title': 'Settings', 'icon': Icons.settings_outlined},
        ];
      case 'alumni':
        return [
          {'title': 'Dashboard', 'icon': Icons.grid_view_outlined},
          {'title': 'Profile', 'icon': Icons.person_outline},
          {'title': 'Announcements', 'icon': Icons.campaign_outlined},
          {'title': 'Jobs', 'icon': Icons.work_outline},
          {'title': 'Settings', 'icon': Icons.settings_outlined},
        ];
      default:
        return [];
    }
  }
}
