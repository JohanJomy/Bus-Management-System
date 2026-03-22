import 'package:flutter/material.dart';
import '../services/bus_service.dart';
import '../models/bus_model.dart';

class FleetManagementScreen extends StatefulWidget {
  const FleetManagementScreen({super.key});

  @override
  State<FleetManagementScreen> createState() => _FleetManagementScreenState();
}

class _FleetManagementScreenState extends State<FleetManagementScreen> {
  final BusService _busService = BusService();
  List<Bus> _buses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    setState(() => _isLoading = true);
    try {
      final buses = await _busService.getAllBuses();
      setState(() => _buses = buses);
    } catch (e) {
      _showError('Failed to load buses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addNewBusToBackend({
    required int busNumber,
    required int totalCapacity,
  }) async {
    try {
      await _busService.addBus(busNumber, totalCapacity);
      await _loadBuses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bus #$busNumber added successfully')),
        );
      }
    } catch (e) {
      _showError('Error adding bus: $e');
    }
  }

  Future<void> _editBusDialog(Bus bus) async {
    final formKey = GlobalKey<FormState>();
    final numberController = TextEditingController(
      text: bus.busNumber.toString(),
    );
    final capacityController = TextEditingController(
      text: bus.totalCapacity.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Bus'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: numberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Bus Number'),
                  validator: (val) => (val == null || val.isEmpty)
                      ? 'Required'
                      : (int.tryParse(val) == null ? 'Invalid number' : null),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Capacity',
                  ),
                  validator: (val) => (val == null || val.isEmpty)
                      ? 'Required'
                      : (int.tryParse(val) == null ? 'Invalid number' : null),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _busService.updateBus(
                    bus.id,
                    int.parse(numberController.text),
                    int.parse(capacityController.text),
                  );
                  await _loadBuses();
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Bus #${numberController.text} updated successfully',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  _showError('Error updating bus: $e');
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBus(Bus bus) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bus'),
        content: Text('Are you sure you want to delete Bus #${bus.busNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _busService.deleteBus(bus.id);
                await _loadBuses();
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Bus #${bus.busNumber} deleted successfully',
                      ),
                    ),
                  );
                }
              } catch (e) {
                _showError('Error deleting bus: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showAddBusDialog() {
    final formKey = GlobalKey<FormState>();
    final numberController = TextEditingController();
    final capacityController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Bus'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: numberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Bus Number'),
                  validator: (val) => (val == null || val.isEmpty)
                      ? 'Required'
                      : (int.tryParse(val) == null ? 'Invalid number' : null),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Capacity',
                  ),
                  validator: (val) => (val == null || val.isEmpty)
                      ? 'Required'
                      : (int.tryParse(val) == null ? 'Invalid number' : null),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _addNewBusToBackend(
                  busNumber: int.parse(numberController.text),
                  totalCapacity: int.parse(capacityController.text),
                );
                if (mounted && Navigator.canPop(ctx)) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 760;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bus & Fleet Management',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showAddBusDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Bus'),
                        ),
                      ],
                    ),
                    SizedBox(height: isCompact ? 16 : 24),
                    _buildSummaryCards(isCompact: isCompact),
                    SizedBox(height: isCompact ? 16 : 24),
                    _buildInventoryTable(),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildSummaryCards({required bool isCompact}) {
    final cards = [
      _SummaryCard(
        title: 'Total Buses',
        value: _buses.length.toString(),
        icon: Icons.directions_bus,
        color: Colors.blue,
      ),
      _SummaryCard(
        title: 'Total Capacity',
        value: _buses.isEmpty
            ? '0'
            : _buses.fold<int>(0, (sum, b) => sum + b.totalCapacity).toString(),
        icon: Icons.group,
        color: Colors.green,
      ),
      _SummaryCard(
        title: 'Avg Capacity',
        value: _buses.isEmpty
            ? '0'
            : (_buses.fold<int>(0, (sum, b) => sum + b.totalCapacity) ~/
                      _buses.length)
                  .toString(),
        icon: Icons.bar_chart,
        color: Colors.orange,
      ),
    ];

    if (isCompact) {
      return Wrap(spacing: 16, runSpacing: 16, children: cards);
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 16),
        Expanded(child: cards[1]),
        const SizedBox(width: 16),
        Expanded(child: cards[2]),
      ],
    );
  }

  Widget _buildInventoryTable() {
    if (_buses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No buses found',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;

          if (isSmallScreen) {
            // Mobile: Card-based list view
            return SingleChildScrollView(
              child: Column(
                children: _buses.map((bus) => _buildBusCard(bus)).toList(),
              ),
            );
          } else {
            // Desktop: flexible full-width table-like layout
            final dividerColor = Colors.grey[200]!;
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Expanded(flex: 2, child: Text('BUS #')),
                      Expanded(flex: 2, child: Text('CAPACITY')),
                      Expanded(flex: 2, child: Text('BUS ID')),
                      Expanded(flex: 2, child: Text('STATUS')),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('ACTIONS'),
                        ),
                      ),
                    ],
                  ),
                ),
                ..._buses.map(
                  (bus) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: dividerColor)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            '#${bus.busNumber}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(flex: 2, child: Text('${bus.totalCapacity}')),
                        Expanded(flex: 2, child: Text('BUS-${bus.id}')),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 30,
                                    minHeight: 30,
                                  ),
                                  onPressed: () => _editBusDialog(bus),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  color: Colors.red,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 30,
                                    minHeight: 30,
                                  ),
                                  onPressed: () => _deleteBus(bus),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildBusCard(Bus bus) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bus #${bus.busNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID: BUS-${bus.id}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Capacity: ${bus.totalCapacity}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editBusDialog(bus),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        color: Colors.red,
                        onPressed: () => _deleteBus(bus),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
