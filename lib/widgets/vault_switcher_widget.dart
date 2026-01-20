import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../domain/entities/vault_entity.dart';
import '../providers/vault_provider.dart';

/// Vault switcher widget - quick vault switching (like Obsidian)
///
/// Displays active vault name and custom dropdown to switch vaults.
/// Features search within dropdown, vault type icons, and smooth animations.
/// Intended for use in app bar or settings screen.
class VaultSwitcherWidget extends StatefulWidget {
  final VaultEntity? currentVault;
  final Function(VaultEntity) onVaultSwitch;

  const VaultSwitcherWidget({
    super.key,
    this.currentVault,
    required this.onVaultSwitch,
  });

  @override
  State<VaultSwitcherWidget> createState() => _VaultSwitcherWidgetState();
}

class _VaultSwitcherWidgetState extends State<VaultSwitcherWidget>
    with SingleTickerProviderStateMixin {
  bool _isDropdownOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    HapticFeedback.lightImpact();
    if (_isDropdownOpen) {
      _removeOverlay();
    } else {
      _showDropdown();
    }
    setState(() => _isDropdownOpen = !_isDropdownOpen);
  }

  void _showDropdown() {
    _overlayEntry = _createDropdownOverlay();
    if (_overlayEntry != null) {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createDropdownOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          _removeOverlay();
          setState(() => _isDropdownOpen = false);
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Transparent backdrop
            Positioned.fill(
              child: Container(color: Colors.transparent),
            ),
            // Dropdown menu
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height + 8,
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 8),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gray200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search bar
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.gray200),
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.spaceGrotesk(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search vaults...',
                              hintStyle: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                color: AppColors.gray500,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 20,
                                color: AppColors.gray700,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.gray100,
                            ),
                            onChanged: (value) {
                              // Trigger rebuild to filter vaults
                              (context as Element).markNeedsBuild();
                            },
                          ),
                        ),

                        // Vault list
                        Consumer<VaultProvider>(
                          builder: (context, vaultProvider, child) {
                            final searchQuery = _searchController.text.toLowerCase();
                            final filteredVaults = vaultProvider.vaults.where((vault) {
                              return vault.name.toLowerCase().contains(searchQuery) ||
                                  vault.type.displayName.toLowerCase().contains(searchQuery);
                            }).toList();

                            if (filteredVaults.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 48,
                                      color: AppColors.gray400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No vaults found',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 14,
                                        color: AppColors.gray700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredVaults.length,
                              itemBuilder: (context, index) {
                                final vault = filteredVaults[index];
                                final isActive = widget.currentVault?.id == vault.id;

                                return InkWell(
                                  onTap: () {
                                    widget.onVaultSwitch(vault);
                                    _removeOverlay();
                                    setState(() => _isDropdownOpen = false);
                                    _searchController.clear();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.fintechTeal.withOpacity(0.1)
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      children: [
                                        // Icon
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            gradient: isActive
                                                ? LinearGradient(
                                                    colors: [
                                                      AppColors.fintechTeal,
                                                      AppColors.fintechTeal.withOpacity(0.7),
                                                    ],
                                                  )
                                                : null,
                                            color: isActive
                                                ? null
                                                : AppColors.gray200,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Center(
                                            child: Text(
                                              vault.type.icon,
                                              style: const TextStyle(fontSize: 20),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Vault info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                vault.name,
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isActive
                                                      ? AppColors.fintechTeal
                                                      : AppColors.black,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                vault.type.displayName,
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 12,
                                                  color: AppColors.gray700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Active indicator
                                        if (isActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.fintechTeal,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'ACTIVE',
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: AppColors.gray200,
                                indent: 64,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.fintechTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.fintechTeal.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              // Icon with animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: Icon(
                      Icons.folder_open,
                      color: AppColors.fintechTeal,
                      size: 20,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),

              // Vault info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Vault',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.currentVault?.name ?? 'No vault selected',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Dropdown arrow
                        AnimatedRotation(
                          turns: _isDropdownOpen ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.fintechTeal,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Vault count badge
              Consumer<VaultProvider>(
                builder: (context, vaultProvider, child) {
                  if (vaultProvider.vaults.length <= 1) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.fintechTeal.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${vaultProvider.vaults.length}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.fintechTeal,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
