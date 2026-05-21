import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

class TransactionsView extends StatefulWidget {
  final String token;
  const TransactionsView({super.key, required this.token});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String _errorMsg = '';
  int _total = 0;

  final _currencyFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _dateFmt = DateFormat('dd MMM yyyy, HH:mm');

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });
    try {
      final result = await ApiService.getTransactions(widget.token, limit: 50);
      setState(() {
        _transactions = result['transactions'] as List<Transaction>;
        _total = result['total'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  void _showDetailDialog(Transaction tx) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Struk Penjualan', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('#${tx.id.toString().padLeft(6, '0')}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(_dateFmt.format(tx.soldAt.toLocal()), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _section('Kendaraan', [
                        _row('Unit', '${tx.vehicleMake} ${tx.vehicleModel} (${tx.vehicleYear})'),
                        _row('Warna', tx.vehicleColor),
                      ]),
                      const SizedBox(height: 14),
                      _section('Pembeli', [
                        _row('Nama', tx.buyerName),
                        _row('Telepon', tx.buyerPhone),
                        _row('No. KTP', tx.buyerIdNumber),
                      ]),
                      const SizedBox(height: 14),
                      _section('Pembayaran', [
                        _row('Metode', tx.paymentMethod),
                        _row('Harga Jual', _currencyFmt.format(tx.salePrice)),
                        if (tx.paymentMethod != 'Cash') ...[
                          _row('Uang Muka', _currencyFmt.format(tx.downPayment)),
                          _row('Tenor', '${tx.installmentMonths} Bulan'),
                          _row('Cicilan/Bulan', _currencyFmt.format(tx.installmentAmount)),
                        ],
                        if (tx.notes.isNotEmpty) _row('Catatan', tx.notes),
                      ]),
                      const SizedBox(height: 14),
                      _section('Info', [
                        _row('Diproses oleh', tx.createdBy),
                        _row('Waktu', _dateFmt.format(tx.soldAt.toLocal())),
                      ]),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tutup'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5, color: Colors.grey)),
        const Divider(height: 6),
        ...rows,
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Riwayat Transaksi', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Total $_total transaksi', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: _fetchTransactions,
                icon: const Icon(Icons.refresh),
                tooltip: 'Muat Ulang',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_errorMsg.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_errorMsg, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
            ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_transactions.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Belum ada transaksi', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Gunakan tab POS untuk mencatat penjualan', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: isMobile
                  ? _buildMobileList(theme)
                  : _buildDesktopTable(theme),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('No.')),
            DataColumn(label: Text('Tanggal')),
            DataColumn(label: Text('Kendaraan')),
            DataColumn(label: Text('Pembeli')),
            DataColumn(label: Text('Metode')),
            DataColumn(label: Text('Harga Jual'), numeric: true),
            DataColumn(label: Text('Aksi')),
          ],
          rows: _transactions.map((tx) {
            Color methodColor = Colors.green;
            if (tx.paymentMethod == 'KPR') methodColor = Colors.blue;
            if (tx.paymentMethod == 'Leasing') methodColor = Colors.orange;

            return DataRow(
              cells: [
                DataCell(Text('#${tx.id.toString().padLeft(4, '0')}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12))),
                DataCell(Text(_dateFmt.format(tx.soldAt.toLocal()), style: const TextStyle(fontSize: 12))),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${tx.vehicleMake} ${tx.vehicleModel}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(tx.vehicleYear.toString(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(tx.buyerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(tx.buyerPhone, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: methodColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: methodColor.withOpacity(0.4)),
                    ),
                    child: Text(tx.paymentMethod, style: TextStyle(color: methodColor, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
                DataCell(Text(_currencyFmt.format(tx.salePrice), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    onPressed: () => _showDetailDialog(tx),
                    tooltip: 'Lihat Struk',
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList(ThemeData theme) {
    return ListView.builder(
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        Color methodColor = Colors.green;
        if (tx.paymentMethod == 'KPR') methodColor = Colors.blue;
        if (tx.paymentMethod == 'Leasing') methodColor = Colors.orange;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            onTap: () => _showDetailDialog(tx),
            leading: CircleAvatar(
              backgroundColor: methodColor.withOpacity(0.15),
              child: Icon(Icons.receipt, color: methodColor, size: 20),
            ),
            title: Text('${tx.vehicleMake} ${tx.vehicleModel}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.buyerName, style: const TextStyle(fontSize: 12)),
                Text(_dateFmt.format(tx.soldAt.toLocal()), style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_currencyFmt.format(tx.salePrice), style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 12)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: methodColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(tx.paymentMethod, style: TextStyle(color: methodColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
