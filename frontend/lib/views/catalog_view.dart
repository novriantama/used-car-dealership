import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/api_service.dart';
import '../widgets/car_card.dart';

class CatalogView extends StatefulWidget {
  final Function(Vehicle) onSelectVehicle;

  const CatalogView({
    super.key,
    required this.onSelectVehicle,
  });

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  final TextEditingController _searchController = TextEditingController();

  List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Filter States
  String _searchQuery = '';
  String _selectedMake = '';
  String _selectedTransmission = '';
  String _selectedPlate = '';
  String _selectedTax = '';

  int? _priceMin;
  int? _priceMax;
  int? _yearMin;
  int? _yearMax;

  int _currentPage = 1;
  int _totalVehicles = 0;
  final int _limit = 12;

  // Static options for filters
  final List<String> _makes = ['Toyota', 'Honda', 'Hyundai', 'Mitsubishi', 'Wuling'];
  final List<String> _transmissions = ['Automatic', 'Manual'];
  final List<String> _plates = ['Ganjil', 'Genap'];
  final List<String> _taxStatuses = ['Aktif', 'Kedaluwarsa'];

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.getVehicles(
        search: _searchQuery,
        make: _selectedMake,
        transmission: _selectedTransmission,
        plateType: _selectedPlate,
        taxStatus: _selectedTax,
        priceMin: _priceMin,
        priceMax: _priceMax,
        yearMin: _yearMin,
        yearMax: _yearMax,
        page: _currentPage,
        limit: _limit,
      );

      setState(() {
        _vehicles = result['vehicles'];
        _totalVehicles = result['total'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '');
        _isLoading = false;
      });
    }
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedMake = '';
      _selectedTransmission = '';
      _selectedPlate = '';
      _selectedTax = '';
      _priceMin = null;
      _priceMax = null;
      _yearMin = null;
      _yearMax = null;
      _currentPage = 1;
    });
    _fetchVehicles();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar Filter (Desktop only)
          if (isDesktop)
            Container(
              width: 280,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.12),
                  ),
                ),
                color: theme.colorScheme.surface.withOpacity(0.4),
              ),
              child: _buildFilterPanel(),
            ),

          // Main Catalog Grid
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      // Search Input
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.12),
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                                _currentPage = 1;
                              });
                              _fetchVehicles();
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari mobil impian Anda (misal: Avanza, Civic)...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                          _currentPage = 1;
                                        });
                                        _fetchVehicles();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Filter Drawer Trigger (Mobile/Tablet only)
                      if (!isDesktop) ...[
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => FractionallySizedBox(
                                heightFactor: 0.85,
                                child: Scaffold(
                                  appBar: AppBar(
                                    title: const Text('Filter Pencarian'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          _resetFilters();
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Reset'),
                                      )
                                    ],
                                  ),
                                  body: _buildFilterPanel(),
                                  bottomNavigationBar: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(50),
                                      ),
                                      child: const Text('Terapkan Filter'),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.tune),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(50, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Active Filters / Statistics
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Menampilkan $_totalVehicles Mobil Bekas Pilihan',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_selectedMake.isNotEmpty ||
                          _selectedTransmission.isNotEmpty ||
                          _selectedPlate.isNotEmpty ||
                          _selectedTax.isNotEmpty)
                        TextButton.icon(
                          onPressed: _resetFilters,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Reset Filter'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Catalog Grid
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage.isNotEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                                  const SizedBox(height: 16),
                                  Text(_errorMessage),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _fetchVehicles,
                                    child: const Text('Coba Lagi'),
                                  )
                                ],
                              ),
                            )
                          : _vehicles.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.search_off_outlined,
                                          size: 64, color: theme.colorScheme.outline),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Mobil tidak ditemukan',
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('Coba ubah kata kunci atau filter pencarian Anda.'),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  itemCount: _vehicles.length,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isDesktop ? 3 : (MediaQuery.of(context).size.width >= 600 ? 2 : 1),
                                    crossAxisSpacing: 20,
                                    mainAxisSpacing: 20,
                                    childAspectRatio: 0.85,
                                  ),
                                  itemBuilder: (context, index) {
                                    return CarCard(
                                      vehicle: _vehicles[index],
                                      onTap: () => widget.onSelectVehicle(_vehicles[index]),
                                    );
                                  },
                                ),
                ),

                // Pagination Row
                if (_totalVehicles > _limit) _buildPagination(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text(
          'Filter Mobil',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // Brand / Make Filter
        _buildSectionHeader('Merk Mobil'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _makes.map((make) {
            final isSelected = _selectedMake == make;
            return ChoiceChip(
              label: Text(make),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  _selectedMake = val ? make : '';
                  _currentPage = 1;
                });
                _fetchVehicles();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Transmission Filter
        _buildSectionHeader('Transmisi'),
        Row(
          children: _transmissions.map((trans) {
            final isSelected = _selectedTransmission == trans;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(trans == 'Automatic' ? 'Matic' : 'Manual'),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      _selectedTransmission = val ? trans : '';
                      _currentPage = 1;
                    });
                    _fetchVehicles();
                  },
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Plate Type Filter (Ganjil/Genap Jakarta)
        _buildSectionHeader('Ganjil / Genap'),
        Row(
          children: _plates.map((plate) {
            final isSelected = _selectedPlate == plate;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(plate),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      _selectedPlate = val ? plate : '';
                      _currentPage = 1;
                    });
                    _fetchVehicles();
                  },
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Tax Status Filter
        _buildSectionHeader('Status Pajak'),
        Row(
          children: _taxStatuses.map((tax) {
            final isSelected = _selectedTax == tax;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(tax == 'Aktif' ? 'Aktif' : 'Mati'),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      _selectedTax = val ? tax : '';
                      _currentPage = 1;
                    });
                    _fetchVehicles();
                  },
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Price Range Filters
        _buildSectionHeader('Harga Maksimal (Juta Rp)'),
        Slider(
          value: (_priceMax ?? 600000000).toDouble() / 1000000,
          min: 100,
          max: 600,
          divisions: 10,
          label: 'Rp ${(_priceMax ?? 600000000) ~/ 1000000} Jt',
          onChanged: (val) {
            setState(() {
              _priceMax = val.round() * 1000000;
              _currentPage = 1;
            });
          },
          onChangeEnd: (val) {
            _fetchVehicles();
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Rp 100 Jt', style: theme.textTheme.bodySmall),
            Text('Rp 600 Jt', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 24),

        // Year Filters
        _buildSectionHeader('Tahun Pembuatan'),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _yearMin,
                hint: const Text('Dari'),
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                items: List.generate(10, (index) => 2015 + index).map((yr) {
                  return DropdownMenuItem(value: yr, child: Text(yr.toString()));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _yearMin = val;
                    _currentPage = 1;
                  });
                  _fetchVehicles();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _yearMax,
                hint: const Text('Sampai'),
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                items: List.generate(10, (index) => 2017 + index).map((yr) {
                  return DropdownMenuItem(value: yr, child: Text(yr.toString()));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _yearMax = val;
                    _currentPage = 1;
                  });
                  _fetchVehicles();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPagination(ThemeData theme) {
    final totalPages = (_totalVehicles / _limit).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _fetchVehicles();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 16),
          Text(
            'Halaman $_currentPage dari $totalPages',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() => _currentPage++);
                    _fetchVehicles();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
