import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';

/// Vault search bar widget with debounce
///
/// Provides search functionality with automatic debouncing
/// to reduce unnecessary state updates.
class VaultSearchBar extends StatefulWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final bool showClearButton;

  const VaultSearchBar({
    super.key,
    required this.query,
    required this.onChanged,
    this.onClear,
    this.showClearButton = true,
  });

  @override
  State<VaultSearchBar> createState() => _VaultSearchBarState();
}

class _VaultSearchBarState extends State<VaultSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(VaultSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounce?.cancel();

    // Start new timer
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(value);
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onChanged('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: _onSearchChanged,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          color: AppColors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Search vaults...',
          hintStyle: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            color: AppColors.gray500,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.gray700,
          ),
          suffixIcon: widget.showClearButton && widget.query.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: AppColors.gray700,
                  ),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
