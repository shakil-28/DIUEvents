import 'package:flutter/material.dart';

class SearchTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear; // Helpful UX addition to reset real-time filtering

  const SearchTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Premium modern color tokens
    final searchBgColor = isDarkMode ? const Color(0xFF1E222B) : const Color(0xFFF1F3F5);
    final iconColor = isDarkMode ? const Color(0xFF9BA1B1) : const Color(0xFF6C727F);
    final hintTextColor = isDarkMode ? const Color(0xFF6C727F) : const Color(0xFF9BA1B1);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1D24);

    return Container(
      decoration: BoxDecoration(
        color: searchBgColor,
        borderRadius: BorderRadius.circular(16.0), // Clean rounded-pill aesthetic
        border: Border.all(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        textInputAction: TextInputAction.search,
        keyboardType: TextInputType.text,
        cursorColor: isDarkMode ? Colors.white : const Color(0xFF1A1D24),
        decoration: InputDecoration(
          hintText: 'Search events, locations, categories...',
          hintStyle: TextStyle(
            color: hintTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Icon(
              Icons.search_rounded, // Smooth rounded icon variations look cleaner
              color: iconColor,
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          suffixIcon: controller != null && controller!.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.cancel_rounded, color: iconColor, size: 18),
                  onPressed: () {
                    controller!.clear();
                    if (onChanged != null) onChanged!('');
                    if (onClear != null) onClear!();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}