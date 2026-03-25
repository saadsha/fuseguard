import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/transformer_provider.dart';
import '../providers/fault_provider.dart';
import '../services/socket_service.dart';
import '../widgets/add_transformer_dialog.dart';
import '../widgets/swipe_to_accept_dialog.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedView = 'Overview';
  SocketService? _socketService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDataAndSockets();
    });
  }

  void _initDataAndSockets() {
    final transformerProvider = Provider.of<TransformerProvider>(context, listen: false);
    transformerProvider.fetchTransformers();

    _socketService = SocketService(
      onTransformerUpdated: (updatedTransformer) {
        // Find existing transformer to check for new faults
        try {
            final oldTransformer = transformerProvider.transformers.firstWhere(
              (t) => t.id == updatedTransformer.id,
            );
            
            // If the incoming data has more blown fuses than what we currently have rendered
            if (updatedTransformer.blownFusesCount > oldTransformer.blownFusesCount) {
               
               // Role-Based Emergency Notification Logic
               final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
               if (user?.role == 'Engineer') {
                 
                 // Try to vibrate the device for physical feedback
                 Vibration.hasVibrator().then((hasVbr) {
                   if (hasVbr == true) {
                     Vibration.vibrate(pattern: [500, 1000, 500, 1000]);
                   }
                 });

                 // Show the intrusive full-screen Swipe-To-Accept Dialog
                 showDialog(
                   context: context,
                   barrierDismissible: false, // Force them to interact with it
                   builder: (BuildContext context) {
                     return SwipeToAcceptDialog(
                       transformer: updatedTransformer,
                       socketService: _socketService!,
                     );
                   },
                 );

               } else {
                 // Standard subtle SnackBar for Viewers
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Row(
                       children: [
                         const Icon(Icons.warning_amber_rounded, color: Colors.white),
                         const SizedBox(width: 8),
                         Text('FAULT DETECTED: Fuse blown on ${updatedTransformer.transformerId}!'),
                       ],
                     ),
                     backgroundColor: Colors.redAccent,
                     behavior: SnackBarBehavior.floating,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                     duration: const Duration(seconds: 5),
                   )
                 );
               }
            }
        } catch (e) {
            // New transformer, just ignore notification
        }

        transformerProvider.updateTransformerLocally(updatedTransformer);
      },
      onJobAccepted: (transformerId) {
        // Mark job accepted globally
        transformerProvider.markJobExternallyAccepted(transformerId);
      }
    );
  }

  @override
  void dispose() {
    _socketService?.dispose();
    super.dispose();
  }

  Widget _buildBodyContent() {
    switch (_selectedView) {
      case 'Overview':
        return _OverviewView();
      case 'Transformers':
        return _TransformersView();
      case 'Users':
        return _UserManagementView();
      case 'Faults':
        return _FaultHistoryView();
      default:
        return _OverviewView();
    }
  }

  String _getAppbarTitle() {
    switch (_selectedView) {
      case 'Overview': return 'Dashboard';
      case 'Transformers': return 'Transformers';
      case 'Users': return 'Users';
      case 'Faults': return 'Fault History';
      default: return 'Dashboard';
    }
  }

  Widget _buildSidebarItem(String title, IconData icon, String viewTag, bool isDesktop) {
    final isSelected = _selectedView == viewTag;
    return Container(
      color: isSelected ? const Color(0xFF2A368F) : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.blueGrey[200], size: 20),
        title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.blueGrey[200], fontSize: 14)),
        selected: isSelected,
        onTap: () {
          setState(() => _selectedView = viewTag);
          if (!isDesktop && Navigator.canPop(context)) {
            Navigator.pop(context); // Close drawer on mobile
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget sidebar = Container(
      width: 260,
      color: const Color(0xFF1B244A),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(Icons.shield, color: Colors.blue[300], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'FuseGuard',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildSidebarItem('Dashboard', Icons.dashboard_outlined, 'Overview', isDesktop),
                if (authProvider.isAdmin) _buildSidebarItem('Transformers', Icons.electrical_services_outlined, 'Transformers', isDesktop),
                if (authProvider.isAdmin) _buildSidebarItem('Users', Icons.people_outline, 'Users', isDesktop),
                if (authProvider.isAdmin || authProvider.isEngineer) _buildSidebarItem('Fault History', Icons.history, 'Faults', isDesktop),
              ],
            ),
          ),
          // Bottom Profile / Indicator
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Text(user?.name.substring(0,1).toUpperCase() ?? 'U', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(user?.name ?? 'Admin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(user?.role ?? 'Role', style: TextStyle(color: Colors.blueGrey[300], fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white54, size: 20),
                  onPressed: () => authProvider.logout(),
                )
              ],
            ),
          )
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      drawer: isDesktop ? null : Drawer(child: sidebar),
      body: Row(
        children: [
          if (isDesktop) sidebar,
          // Main Content Area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      if (!isDesktop) ...[
                        Builder(
                          builder: (ctx) => IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () => Scaffold.of(ctx).openDrawer(),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _getAppbarTitle(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: _buildBodyContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransformerProvider>(context);
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)));
    }

    final int totalTransformers = provider.totalTransformers;
    final int activeFaults = provider.transformers.where((t) => t.status == 'Fault').length;
    final int normalStatus = totalTransformers - activeFaults;
    final double faultPercentage = totalTransformers > 0 ? (activeFaults / totalTransformers * 100) : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${user?.name ?? 'Admin'}!',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 24),
          // 4 Stat Cards Array
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard(
                    context, constraints.maxWidth,
                    'Total Transformers', totalTransformers.toString(),
                    'Managed across all sites', Icons.settings_outlined,
                  ),
                  _buildStatCard(
                    context, constraints.maxWidth,
                    'Active Faults', activeFaults.toString(),
                    '${faultPercentage.toStringAsFixed(1)}% of units', Icons.warning_amber_rounded,
                  ),
                  _buildStatCard(
                    context, constraints.maxWidth,
                    'Normal Status', normalStatus.toString(),
                    'Operating within parameters', Icons.shield_outlined,
                  ),
                  if (context.watch<AuthProvider>().isAdmin)
                    _buildStatCard(
                      context, constraints.maxWidth,
                      'Total Users', context.watch<AuthProvider>().totalUsers.toString(),
                      'Admins, Engineers, & Viewers', Icons.people_outline,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          // Live Status Section
          const Text(
            'Live Transformer Status',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 4),
          Text(
            'Real-time data from all monitored transformers.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 450,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 220, // fixed height for cards
            ),
            itemCount: provider.transformers.length,
            itemBuilder: (context, index) {
              final transformer = provider.transformers[index];
              return _buildTransformerCard(transformer);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, double totalWidth, String title, String value, String subtitle, IconData icon) {
    double itemWidth = (totalWidth - (16 * 3)) / 4;
    if (totalWidth < 800) itemWidth = (totalWidth - 16) / 2;
    if (totalWidth < 500) itemWidth = totalWidth;
    
    return Container(
      width: itemWidth < 200 ? 200 : itemWidth,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF374151), fontSize: 13)),
              Icon(icon, size: 18, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildTransformerCard(transformer) {
    final isFaulty = transformer.status == 'Fault';
    
    final borderColor = isFaulty ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB);
    final bgColor = isFaulty ? const Color(0xFFFEF2F2) : Colors.white;
    final pillBg = isFaulty ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transformer.transformerId, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(transformer.location, style: TextStyle(fontSize: 13, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isFaulty ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      isFaulty ? 'FUSE BLOWN' : 'NORMAL',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                    ),
                  ],
                ),
              )
            ],
          ),
          const Spacer(), // pushes next elements down
          
          // Data Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Voltage', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    const SizedBox(height: 2),
                    Text('${transformer.currentVoltage} V', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    const SizedBox(height: 2),
                    Text('${transformer.currentAmperage} A', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          
          // Fuses Row
          Text('Fuses', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 6),
          Row(
            children: transformer.fuses.map<Widget>((fuse) {
              final fuseHealthy = fuse.status == 'Healthy';
              if (fuseHealthy) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Icon(Icons.hexagon_outlined, color: Colors.green, size: 18),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Icon(Icons.change_history, color: Colors.red, size: 18), // change_history is a triangle
                );
              }
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TransformersView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransformerProvider>(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Manage Transformers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Add Transformer'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddTransformerDialog(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1B244A),
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
          SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: provider.transformers.length,
            itemBuilder: (context, index) {
              final t = provider.transformers[index];
              return Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: ListTile(
                  leading: Icon(Icons.electrical_services, color: t.status == 'Fault' ? Colors.red : Colors.green),
                  title: Text(t.transformerId, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(t.location),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${t.fuses.length} Fuses', style: TextStyle(color: Colors.grey[600])),
                      SizedBox(width: 16),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue[300]),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AddTransformerDialog(transformer: t),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red[300]),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Transformer'),
                              content: Text('Are you sure you want to delete ${t.transformerId}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    final provider = Provider.of<TransformerProvider>(context, listen: false);
                                    await provider.deleteTransformer(t.id);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[600],
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Delete'),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}

class _FaultHistoryView extends StatefulWidget {
  @override
  __FaultHistoryViewState createState() => __FaultHistoryViewState();
}

class __FaultHistoryViewState extends State<_FaultHistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FaultProvider>(context, listen: false).fetchFaults();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FaultProvider>(context);
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final canResolve = user?.role == 'Admin' || user?.role == 'Engineer';

    if (provider.isLoading && provider.faults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.faults.isEmpty) {
      return Center(child: Text(provider.error!, style: const TextStyle(color: Colors.red)));
    }

    if (provider.faults.isEmpty) {
      return const Center(child: Text('No fault history found.', style: TextStyle(fontSize: 16, color: Colors.grey)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fault History Log', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.faults.length,
            itemBuilder: (context, index) {
              final fault = provider.faults[index];
              final isResolved = fault.status == 'Resolved';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isResolved ? Colors.green.shade200 : Colors.red.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: isResolved ? Colors.green.shade50 : Colors.red.shade50,
                    child: Icon(
                      isResolved ? Icons.check_circle : Icons.warning_amber_rounded,
                      color: isResolved ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                    '${fault.transformerName} - ${fault.fuseId} Blown', 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Location: ${fault.location}'),
                      const SizedBox(height: 4),
                      Text(
                        'Detected: ${DateFormat('yyyy-MM-dd HH:mm').format(fault.detectedAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (isResolved && fault.resolvedAt != null)
                        Text(
                          'Resolved: ${DateFormat('yyyy-MM-dd HH:mm').format(fault.resolvedAt!)}',
                          style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                  trailing: (!isResolved && canResolve) ? ElevatedButton.icon(
                    icon: const Icon(Icons.build, size: 16),
                    label: const Text('Mark Resolved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final success = await provider.resolveFault(fault.id);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fault marked as resolved.')),
                        );
                      }
                    },
                  ) : (isResolved ? Chip(
                       label: const Text('Resolved', style: TextStyle(color: Colors.green, fontSize: 12)),
                       backgroundColor: Colors.green.shade50,
                       side: BorderSide.none,
                     ) : null),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}

class _UserManagementView extends StatefulWidget {
  @override
  __UserManagementViewState createState() => __UserManagementViewState();
}

class __UserManagementViewState extends State<_UserManagementView> {
  List<dynamic> users = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('http://192.168.1.2:5000/api/users'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          users = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load users: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.delete(
        Uri.parse('http://192.168.1.2:5000/api/users/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        _fetchUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete user')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text(error!, style: const TextStyle(color: Colors.red)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('User Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final u = users[index];
              return Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(u['name'].toString().substring(0, 1).toUpperCase()),
                  ),
                  title: Text(u['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${u['email']} • ${u['role']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[300]),
                    onPressed: () {
                      _deleteUser(u['_id']);
                    },
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
