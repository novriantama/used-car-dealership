import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import '../models/vehicle.dart';
import '../services/api_service.dart';

class DetailView extends StatefulWidget {
  final Vehicle vehicle;
  final VoidCallback onBack;

  const DetailView({
    super.key,
    required this.vehicle,
    required this.onBack,
  });

  @override
  State<DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> {
  // Credit Simulator States
  double _downPayment = 0.0;
  int _tenureYears = 3; // Default 3 years (36 months)
  final TextEditingController _dpController = TextEditingController();

  // Gallery Slideshow State
  int _currentSlideIndex = 0;
  late PageController _pageController;

  // Local leasing flat rates per year
  final Map<int, double> _interestRates = {
    1: 0.055, // 5.5%
    2: 0.060, // 6.0%
    3: 0.065, // 6.5%
    4: 0.070, // 7.0%
    5: 0.080, // 8.0%
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    // Default DP to 20% of vehicle price
    _downPayment = widget.vehicle.price * 0.20;
    _dpController.text = _downPayment.round().toString();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dpController.dispose();
    super.dispose();
  }

  String _getImageUrl(String url) => ApiService.getImageUrl(url);

  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  // Calculate monthly installments based on local Indonesian leasing rules (Flat Rate)
  double _calculateMonthlyInstallment() {
    final vehiclePrice = widget.vehicle.price;
    final loanPrincipal = vehiclePrice - _downPayment;

    if (loanPrincipal <= 0) return 0;

    final rate = _interestRates[_tenureYears] ?? 0.065;
    final totalInterest = loanPrincipal * rate * _tenureYears;
    final totalLoan = loanPrincipal + totalInterest;
    final totalMonths = _tenureYears * 12;

    return totalLoan / totalMonths;
  }

  // Generate WhatsApp message and redirect link
  String _getWhatsAppUrl() {
    final v = widget.vehicle;
    final formattedPrice = _formatPrice(v.price.toDouble());
    
    // Construct VDP URL using current page URL mapping
    final baseUri = Uri.parse(Uri.base.toString());
    final vehicleUrl = 'http://${baseUri.host}:${baseUri.port}/?car=${v.id}';

    final text = 'Halo Used Car Storefront, saya tertarik dengan mobil berikut:\n'
        '🚙 *${v.year} ${v.make} ${v.model}*\n'
        '💰 Harga: *$formattedPrice*\n'
        '📍 Lokasi: ${v.location}\n'
        '🔗 Lihat Detail: $vehicleUrl\n\n'
        'Bisa tolong bantu jadwalkan sesi test drive?';

    final encodedText = Uri.encodeComponent(text);
    // WhatsApp Hotline (mock number: +62 812-3456-7890)
    return 'https://wa.me/6281234567890?text=$encodedText';
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final bool isTaxActive = v.taxStatus.toLowerCase() == 'aktif';
    final Color taxColor = isTaxActive ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text('${v.make} ${v.model} (${v.year})'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Gallery and Inspection
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGallery(v, theme),
                        const SizedBox(height: 32),
                        _buildInspectionSummary(v, theme),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Right Side: Specs, Simulation & CTA
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSpecsSummary(v, theme, taxColor, isTaxActive),
                        const SizedBox(height: 24),
                        _buildCreditSimulator(theme),
                        const SizedBox(height: 24),
                        _buildWhatsAppCTA(theme),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGallery(v, theme),
                  const SizedBox(height: 24),
                  _buildSpecsSummary(v, theme, taxColor, isTaxActive),
                  const SizedBox(height: 24),
                  _buildInspectionSummary(v, theme),
                  const SizedBox(height: 24),
                  _buildCreditSimulator(theme),
                  const SizedBox(height: 24),
                  _buildWhatsAppCTA(theme),
                ],
              ),
      ),
    );
  }

  // Gallery Widget
  Widget _buildGallery(Vehicle v, ThemeData theme) {
    final urls = v.imageUrls.isNotEmpty ? v.imageUrls : [''];

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              // Main Image PageView
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: urls.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentSlideIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final url = urls[index];
                      return Image.network(
                        _getImageUrl(url),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: theme.colorScheme.surfaceVariant,
                          child: Icon(Icons.directions_car, size: 96, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Left/Right Navigation Arrows Overlay
              if (urls.length > 1) ...[
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                          onPressed: () {
                            if (_currentSlideIndex > 0) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _pageController.animateToPage(
                                urls.length - 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                          onPressed: () {
                            if (_currentSlideIndex < urls.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _pageController.animateToPage(
                                0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                // Indicator dots overlay at the bottom center of the page view
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      urls.length,
                      (index) {
                        final isSelected = _currentSlideIndex == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isSelected ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.white70,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (urls.length > 1) ...[
          const SizedBox(height: 16),
          // Horizontal list of thumbnails
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              itemBuilder: (context, index) {
                final isSelected = _currentSlideIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: InkWell(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Opacity(
                          opacity: isSelected ? 1.0 : 0.6,
                          child: Image.network(
                            _getImageUrl(urls[index]),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: theme.colorScheme.surfaceVariant,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ]
      ],
    );
  }
  // Specs Specifications Widget
  Widget _buildSpecsSummary(Vehicle v, ThemeData theme, Color taxColor, bool isTaxActive) {
    final formatter = NumberFormat.decimalPattern('id_ID');
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${v.year}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: v.plateType.toLowerCase() == 'ganjil'
                        ? Colors.amber.shade700
                        : Colors.indigo.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    v.plateType,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${v.make} ${v.model}',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '📍 ${v.location}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(
              'Harga Cash',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            Text(
              _formatPrice(v.price.toDouble()),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildSpecRow('Transmisi', v.transmission, Icons.settings_input_component),
            _buildSpecRow('Bahan Bakar', v.fuelType, Icons.local_gas_station),
            _buildSpecRow('Jarak Tempuh', '${formatter.format(v.mileage)} km', Icons.speed),
            _buildSpecRow('Kapasitas Mesin', v.engineCapacity > 0 ? '${formatter.format(v.engineCapacity)} cc' : 'EV', Icons.bolt),
            _buildSpecRow('Warna Cat', v.color, Icons.color_lens),
            _buildSpecRow(
              'Status Pajak',
              isTaxActive ? 'Aktif s/d ${v.taxExpiryDate}' : 'Expired sejak ${v.taxExpiryDate}',
              Icons.calendar_month,
              valueColor: taxColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String title, String value, IconData icon, {Color? valueColor}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8), fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // 100-Point Inspection Widget
  Widget _buildInspectionSummary(Vehicle v, ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Laporan Inspeksi 100-Titik',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Mobil ini telah lolos pemeriksaan ketat oleh inspektur profesional kami.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInspectionGauge(theme, 'Mesin', v.inspectionEngine, Colors.orange),
                _buildInspectionGauge(theme, 'Interior', v.inspectionInterior, Colors.teal),
                _buildInspectionGauge(theme, 'Eksterior', v.inspectionExterior, Colors.blue),
              ],
            ),
            if (v.inspectionNotes.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Catatan Inspeksi:',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                v.inspectionNotes,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionGauge(ThemeData theme, String section, int score, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 72,
              width: 72,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 8,
                backgroundColor: theme.colorScheme.outline.withOpacity(0.1),
                color: color,
              ),
            ),
            Text(
              '$score',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          section,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        )
      ],
    );
  }

  // Credit Simulator Calculator Widget
  Widget _buildCreditSimulator(ThemeData theme) {
    final double monthlyInstallment = _calculateMonthlyInstallment();
    final double maxDp = widget.vehicle.price * 0.90;
    final double minDp = widget.vehicle.price * 0.10;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Simulasi Kredit',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // DP Input
            Text(
              'Uang Muka (DP)',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _downPayment,
                    min: minDp,
                    max: maxDp,
                    divisions: 16,
                    onChanged: (val) {
                      setState(() {
                        _downPayment = val;
                        _dpController.text = val.round().toString();
                      });
                    },
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Min: ${_formatPrice(minDp)}', style: theme.textTheme.labelSmall),
                Text('Max: ${_formatPrice(maxDp)}', style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                labelText: 'DP Nominal',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (val) {
                final double? dpVal = double.tryParse(val);
                if (dpVal != null && dpVal >= minDp && dpVal <= maxDp) {
                  setState(() {
                    _downPayment = dpVal;
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // Tenure selector
            Text(
              'Tenor Pinjaman',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [1, 2, 3, 4, 5].map((years) {
                final isSelected = _tenureYears == years;
                return ChoiceChip(
                  label: Text('$years Thn'),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _tenureYears = years;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Result
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Angsuran Bulanan',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatPrice(monthlyInstallment),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Bunga Flat ${_interestRates[_tenureYears]! * 100}% p.a.',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // WhatsApp CTA Button Widget
  Widget _buildWhatsAppCTA(ThemeData theme) {
    // Dynamic import window for Web redirect if possible, otherwise we open Uri.
    // In Flutter Web, we can easily use a link URL launcher or standard html anchor window.open
    // For this prototype, we will use standard Uri launch URL. Wait! We can use html window if compiled for web:
    // import 'dart:html' as html;
    // We can open it directly in a new window: html.window.open(url, '_blank');
    // Since we compile specifically for Flutter Web, let's write a standard method using an html redirect which is 100% reliable for web.
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Open WhatsApp link in new browser tab
          final url = _getWhatsAppUrl();
          // We can use a universal launch or direct javascript window open via dart:js or dart:html.
          // Since we are compiling to Web, we can do a Javascript evaluation or dart:html.
          // Let's use a nice, universally compatible approach inside Dart for Web:
          // dart:html is perfect! Let's import it conditionally or directly since it is a Web target.
          // We can write: import 'dart:html' as html; html.window.open(url, 'whatsapp');
          // Let's use standard dart:html.
          // Wait, is it safe to compile if we use dart:html? Yes, we are specifically compiling for Flutter Web as requested.
          // But to be perfectly safe, let's write the redirect using an iframe or html window.
          // Let's just import 'dart:html' directly.
          try {
            html.window.open(url, '_blank');
          } catch (e) {
            debugPrint('Error launching WhatsApp link: $e');
          }
        },
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF25D366), // WhatsApp Green
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25D366).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Hubungi Sales via WhatsApp',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
