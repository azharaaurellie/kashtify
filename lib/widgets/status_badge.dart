import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? notes;

  const StatusBadge({
    super.key,
    required this.status,
    this.notes,
  });

  @override
  Widget build(BuildContext context) {
    // Check for menunggu_konfirmasi via notes field first
    if (notes == 'menunggu_konfirmasi') {
      return _buildBadge('Menunggu', AppTheme.accentColor, Colors.white);
    }

    switch (status) {
      case 'lunas':
        return _buildBadge('Lunas', AppTheme.successColor, Colors.white);
      case 'terlambat':
        return _buildBadge('Terlambat', AppTheme.errorColor, Colors.white);
      case 'belum_lunas':
      default:
        return _buildBadge(
            'Belum Lunas', const Color(0xFF718096), Colors.white);
    }
  }

  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bgColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: bgColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
