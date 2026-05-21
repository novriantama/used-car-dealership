import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

class PosView extends StatefulWidget {
  final String token;
  const PosView({super.key, required this.token});

  @override
  State<PosView> createState() => _PosViewState();
}

class _PosViewState extends State<PosView> {
  // Vehicle selection state
  List<Vehicle> _vehicles = [];
  bool _loadingVehicles = true;
  Vehicle? _selectedVehicle;
  String _vehicleSearch = '';

  // Form state
  final _formKey = GlobalKey<FormState>();
  final _buyerNameCtrl = TextEditingController();
  final _buyerPhoneCtrl = TextEditingController();
  final _buyerIdCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController();
  final _dpCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  String _paymentMethod = 'Cash';
  int _installmentMonths = 12;
  bool _isSubmitting = false;
  String _errorMsg = '';

  final _currencyFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchAvailableVehicles();
  }

  @override
  void dispose() {
    _buyerNameCtrl.dispose();
    _buyerPhoneCtrl.dispose();
    _buyerIdCtrl.dispose();
    _salePriceCtrl.dispose();
    _dpCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailableVehicles() async {
    setState(() => _loadingVehicles = true);
    try {
      final result = await ApiService.getVehicles(limit: 100, taxStatus: '');
      final all = result['vehicles'] as List<Vehicle>;
      setState(() {
        _vehicles = all.where((v) => v.status == 'Available').toList();
        _loadingVehicles = false;
      });
    } catch (e) {
      setState(() => _loadingVehicles = false);
    }
  }

  List<Vehicle> get _filteredVehicles {
    if (_vehicleSearch.isEmpty) return _vehicles;
    final q = _vehicleSearch.toLowerCase();
    return _vehicles.where((v) =>
      v.make.toLowerCase().contains(q) ||
      v.model.toLowerCase().contains(q) ||
      v.year.toString().contains(q)
    ).toList();
  }

  int get _salePrice => int.tryParse(_salePriceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  int get _dpAmount => int.tryParse(_dpCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  int get _installmentAmount {
    if (_paymentMethod == 'Cash') return 0;
    final remaining = _salePrice - _dpAmount;
    if (remaining <= 0 || _installmentMonths <= 0) return 0;
    // Flat rate: 1yr=0.9%, 2yr=1.0%, 3yr=1.1%, 4yr=1.15%, 5yr=1.2% monthly
    const rates = {12: 0.009, 24: 0.010, 36: 0.011, 48: 0.0115, 60: 0.012};
    final rate = rates[_installmentMonths] ?? 0.011;
    return ((remaining + (remaining * rate * _installmentMonths)) / _installmentMonths).round();
  }

  Future<void> _processTransaction() async {
    if (_selectedVehicle == null) {
      setState(() => _errorMsg = 'Pilih kendaraan terlebih dahulu');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Penjualan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kendaraan: ${_selectedVehicle!.make} ${_selectedVehicle!.model} (${_selectedVehicle!.year})'),
            const SizedBox(height: 4),
            Text('Pembeli: ${_buyerNameCtrl.text}'),
            const SizedBox(height: 4),
            Text('Harga Jual: ${_currencyFmt.format(_salePrice)}'),
            const SizedBox(height: 12),
            const Text(
              'Setelah dikonfirmasi, status kendaraan akan berubah menjadi TERJUAL dan tidak dapat dibatalkan.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Ya, Proses Penjualan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
      _errorMsg = '';
    });

    try {
      final data = {
        'vehicle_id': _selectedVehicle!.id,
        'buyer_name': _buyerNameCtrl.text.trim(),
        'buyer_phone': _buyerPhoneCtrl.text.trim(),
        'buyer_id_number': _buyerIdCtrl.text.trim(),
        'payment_method': _paymentMethod,
        'sale_price': _salePrice,
        'down_payment': _dpAmount,
        'installment_months': _paymentMethod == 'Cash' ? 0 : _installmentMonths,
        'installment_amount': _installmentAmount,
        'notes': _notesCtrl.text.trim(),
      };
      final tx = await ApiService.createTransaction(data, widget.token);
      setState(() => _isSubmitting = false);
      if (mounted) _showReceiptDialog(tx);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMsg = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  void _showReceiptDialog(Transaction tx) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        child: Container(
          constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 48),
                    const SizedBox(height: 8),
                    const Text('Transaksi Berhasil!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('No. Transaksi: #${tx.id.toString().padLeft(6, '0')}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _receiptSection('Kendaraan', [
                        _receiptRow('Unit', '${tx.vehicleMake} ${tx.vehicleModel}'),
                        _receiptRow('Tahun', tx.vehicleYear.toString()),
                        _receiptRow('Warna', tx.vehicleColor),
                      ]),
                      const SizedBox(height: 16),
                      _receiptSection('Data Pembeli', [
                        _receiptRow('Nama', tx.buyerName),
                        _receiptRow('No. Telepon', tx.buyerPhone),
                        _receiptRow('No. KTP', tx.buyerIdNumber),
                      ]),
                      const SizedBox(height: 16),
                      _receiptSection('Transaksi', [
                        _receiptRow('Metode Pembayaran', tx.paymentMethod),
                        _receiptRow('Harga Jual', _currencyFmt.format(tx.salePrice)),
                        if (tx.paymentMethod != 'Cash') ...[
                          _receiptRow('Uang Muka (DP)', _currencyFmt.format(tx.downPayment)),
                          _receiptRow('Tenor', '${tx.installmentMonths} Bulan'),
                          _receiptRow('Cicilan/Bulan', _currencyFmt.format(tx.installmentAmount)),
                        ],
                        if (tx.notes.isNotEmpty) _receiptRow('Catatan', tx.notes),
                        _receiptRow('Diproses oleh', tx.createdBy),
                        _receiptRow('Tanggal', DateFormat('dd MMM yyyy, HH:mm').format(tx.soldAt.toLocal())),
                      ]),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                        label: const Text('Tutup'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      _resetForm();
      _fetchAvailableVehicles();
    });
  }

  Widget _receiptSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
        const Divider(height: 8),
        ...rows,
      ],
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _buyerNameCtrl.clear();
    _buyerPhoneCtrl.clear();
    _buyerIdCtrl.clear();
    _salePriceCtrl.clear();
    _dpCtrl.text = '0';
    _notesCtrl.clear();
    setState(() {
      _selectedVehicle = null;
      _paymentMethod = 'Cash';
      _installmentMonths = 12;
      _errorMsg = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 900;

    return isWide ? _buildWideLayout(theme) : _buildNarrowLayout(theme);
  }

  Widget _buildWideLayout(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel — vehicle selector
        SizedBox(
          width: 340,
          child: _buildVehicleSelector(theme),
        ),
        const VerticalDivider(width: 1),
        // Right panel — transaction form
        Expanded(child: _buildTransactionForm(theme)),
      ],
    );
  }

  Widget _buildNarrowLayout(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildVehicleSelector(theme, shrink: true),
          const SizedBox(height: 16),
          _buildTransactionForm(theme),
        ],
      ),
    );
  }

  Widget _buildVehicleSelector(ThemeData theme, {bool shrink = false}) {
    return Container(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pilih Kendaraan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari merk, model, tahun...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => setState(() => _vehicleSearch = v),
                ),
              ],
            ),
          ),
          SizedBox(
            height: shrink ? 300 : null,
            child: _loadingVehicles
                ? const Center(child: CircularProgressIndicator())
                : _filteredVehicles.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('Tidak ada kendaraan tersedia')),
                      )
                    : ListView.builder(
                        shrinkWrap: !shrink,
                        physics: shrink ? const AlwaysScrollableScrollPhysics() : null,
                        itemCount: _filteredVehicles.length,
                        itemBuilder: (ctx, i) {
                          final v = _filteredVehicles[i];
                          final isSelected = _selectedVehicle?.id == v.id;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedVehicle = v;
                                _salePriceCtrl.text = v.price.toString();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline.withOpacity(0.2),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      v.imageUrls.isNotEmpty ? ApiService.getImageUrl(v.imageUrls[0]) : '',
                                      width: 56,
                                      height: 42,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 56,
                                        height: 42,
                                        color: theme.colorScheme.surfaceVariant,
                                        child: const Icon(Icons.directions_car, size: 20),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${v.make} ${v.model}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: isSelected ? theme.colorScheme.primary : null,
                                            )),
                                        Text('${v.year} • ${v.color}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            )),
                                        Text(
                                          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v.price),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected vehicle banner
            if (_selectedVehicle != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _selectedVehicle!.imageUrls.isNotEmpty ? ApiService.getImageUrl(_selectedVehicle!.imageUrls[0]) : '',
                        width: 80,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 58,
                          color: theme.colorScheme.surfaceVariant,
                          child: const Icon(Icons.directions_car),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedVehicle!.make} ${_selectedVehicle!.model}',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text('${_selectedVehicle!.year} • ${_selectedVehicle!.color} • ${_selectedVehicle!.plateType}',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                          Text(
                            _currencyFmt.format(_selectedVehicle!.price),
                            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _selectedVehicle = null),
                      tooltip: 'Batalkan pilihan',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2), style: BorderStyle.solid),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_car_outlined, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Text('Pilih kendaraan dari panel sebelah kiri', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            Text('Data Pembeli', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            TextFormField(
              controller: _buyerNameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Lengkap Pembeli', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _buyerPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'No. Telepon / WhatsApp', prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder()),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _buyerIdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'No. KTP', prefixIcon: Icon(Icons.badge_outlined), border: OutlineInputBorder()),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Wajib diisi' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text('Pembayaran', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Payment method selector
            Row(
              children: ['Cash', 'KPR', 'Leasing'].map((method) {
                final selected = _paymentMethod == method;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(method),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _paymentMethod = method;
                      if (method == 'Cash') _dpCtrl.text = '0';
                    }),
                    selectedColor: theme.colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: selected ? theme.colorScheme.primary : null,
                      fontWeight: selected ? FontWeight.bold : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _salePriceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga Jual (Rp)', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = int.tryParse(v?.replaceAll(RegExp(r'[^0-9]'), '') ?? '');
                if (n == null || n <= 0) return 'Masukkan harga jual yang valid';
                return null;
              },
            ),

            if (_paymentMethod != 'Cash') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dpCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Uang Muka / DP (Rp)', prefixIcon: Icon(Icons.payment), border: OutlineInputBorder()),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _installmentMonths,
                      decoration: const InputDecoration(labelText: 'Tenor', border: OutlineInputBorder()),
                      items: [12, 24, 36, 48, 60].map((m) => DropdownMenuItem(value: m, child: Text('$m Bulan'))).toList(),
                      onChanged: (v) => setState(() => _installmentMonths = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimasi Cicilan/Bulan:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      _currencyFmt.format(_installmentAmount),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Catatan Tambahan (opsional)', prefixIcon: Icon(Icons.notes), border: OutlineInputBorder()),
            ),

            if (_errorMsg.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMsg, style: TextStyle(color: theme.colorScheme.onErrorContainer))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_isSubmitting || _selectedVehicle == null) ? null : _processTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.point_of_sale),
                label: Text(
                  _isSubmitting ? 'Memproses...' : 'Proses Penjualan',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
