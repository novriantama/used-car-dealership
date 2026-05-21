import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';

class CarCard extends StatefulWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;

  const CarCard({
    super.key,
    required this.vehicle,
    required this.onTap,
  });

  @override
  State<CarCard> createState() => _CarCardState();
}

class _CarCardState extends State<CarCard> {
  bool _isHovered = false;

  String _formatPrice(int price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  String _formatMileage(int mileage) {
    final formatter = NumberFormat.decimalPattern('id_ID');
    return '${formatter.format(mileage)} km';
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final theme = Theme.of(context);

    // Color indicators for badges
    final bool isTaxActive = v.taxStatus.toLowerCase() == 'aktif';
    final Color taxColor = isTaxActive ? Colors.green : Colors.red;
    final Color plateColor = v.plateType.toLowerCase() == 'ganjil'
        ? Colors.amber.shade700
        : Colors.indigo.shade600;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _isHovered
              ? (Matrix4.identity()..translate(0, -6, 0)..scale(1.02))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? theme.colorScheme.primary.withOpacity(0.5)
                  : theme.colorScheme.outline.withOpacity(0.15),
              width: _isHovered ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? theme.colorScheme.primary.withOpacity(0.12)
                    : Colors.black.withOpacity(0.04),
                blurRadius: _isHovered ? 16 : 8,
                offset: _isHovered ? const Offset(0, 8) : const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car Image with Status Badge
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.6,
                      child: Image.network(
                        v.imageUrls.isNotEmpty
                            ? v.imageUrls[0]
                            : 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&q=80&w=600',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: theme.colorScheme.surfaceVariant,
                            child: Icon(
                              Icons.directions_car_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                    // Status tag (Sold / Reserved / Available)
                    if (v.status != 'Available')
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: v.status == 'Sold'
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            v.status == 'Sold' ? 'DIJUAL' : 'RESERVED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    // Plate tag (Ganjil/Genap)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: plateColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          v.plateType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Car Details
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Year & Make
                      Text(
                        '${v.year} • ${v.make}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Model
                      Text(
                        v.model,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Core Badges (Transmission, Mileage, Fuel)
                      Row(
                        children: [
                          _buildDetailBadge(
                            context,
                            Icons.settings_input_component,
                            v.transmission,
                          ),
                          const SizedBox(width: 8),
                          _buildDetailBadge(
                            context,
                            Icons.speed,
                            _formatMileage(v.mileage),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: theme.colorScheme.outline.withOpacity(0.1)),
                      const SizedBox(height: 12),
                      // Price & Inspection Score
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Harga Cash',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatPrice(v.price),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.primary,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Inspection Score Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.verified_user,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${v.averageInspectionScore}% OK',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Tax Status indicator
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: taxColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isTaxActive ? 'Pajak Aktif' : 'Pajak Expired',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: taxColor.withOpacity(0.85),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailBadge(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
