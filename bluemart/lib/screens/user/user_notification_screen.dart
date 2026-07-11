import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class UserNotificationScreen extends StatefulWidget {
  const UserNotificationScreen({super.key});

  @override
  State<UserNotificationScreen> createState() => _UserNotificationScreenState();
}

class _UserNotificationScreenState extends State<UserNotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<_NotificationItem> _allNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final service = NotificationService();
    final data = await service.getNotifications();
    
    _allNotifications.clear();
    for (var notif in data) {
      _allNotifications.add(_NotificationItem(
        icon: notif['type'] == 'promo' ? Icons.discount : Icons.payment,
        iconColor: notif['type'] == 'promo' ? const Color(0xFFF97316) : const Color(0xFF22C55E),
        title: notif['title'] ?? '',
        message: notif['message'] ?? '',
        time: DateTime.parse(notif['timestamp']),
        type: notif['type'] ?? 'pesanan',
        isRead: notif['isRead'] ?? false,
      ));
    }
    
    // Fallback if empty (keep dummy data for preview)
    if (_allNotifications.isEmpty) {
      _generateSampleNotifications();
    }
    
    setState(() => _isLoading = false);
  }

  void _generateSampleNotifications() {
    final now = DateTime.now();
    _allNotifications.addAll([
      _NotificationItem(
        icon: Icons.local_shipping,
        iconColor: const Color(0xFF3B82F6),
        title: 'Pesanan Dikirim',
        message: 'Pesanan #123 sudah dikirim dan sedang dalam perjalanan.',
        time: now.subtract(const Duration(minutes: 5)),
        type: 'pesanan',
        isRead: false,
      ),
      _NotificationItem(
        icon: Icons.discount,
        iconColor: const Color(0xFFF97316),
        title: 'Promo Spesial!',
        message: 'Diskon 50% Flash Sale hari ini. Buruan sebelum kehabisan!',
        time: now.subtract(const Duration(hours: 1)),
        type: 'promo',
        isRead: false,
      ),
    ]);
  }

  List<_NotificationItem> get _filteredNotifications {
    switch (_tabController.index) {
      case 1:
        return _allNotifications.where((n) => n.type == 'pesanan').toList();
      case 2:
        return _allNotifications.where((n) => n.type == 'promo').toList();
      default:
        return _allNotifications;
    }
  }

  void _markAllRead() {
    setState(() {
      for (var n in _allNotifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi telah dibaca'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton.icon(
            onPressed: _markAllRead,
            icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
            label: const Text(
              'Baca Semua',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Semua'),
                  if (_allNotifications.any((n) => !n.isRead))
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_allNotifications.where((n) => !n.isRead).length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Tab(text: 'Pesanan'),
            const Tab(text: 'Promo'),
          ],
        ),
      ),
      body: _buildNotificationList(),
    );
  }

  Widget _buildNotificationList() {
    final notifications = _filteredNotifications;
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 50,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tidak Ada Notifikasi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tenang, kami akan memberitahu jika ada\ninfo terbaru untuk Anda',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Group by date
    final today = <_NotificationItem>[];
    final yesterday = <_NotificationItem>[];
    final older = <_NotificationItem>[];
    final now = DateTime.now();

    for (var n in notifications) {
      final diff = now.difference(n.time);
      if (diff.inDays == 0) {
        today.add(n);
      } else if (diff.inDays == 1) {
        yesterday.add(n);
      } else {
        older.add(n);
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (today.isNotEmpty) _buildDateSection('Hari Ini', today),
          if (yesterday.isNotEmpty) _buildDateSection('Kemarin', yesterday),
          if (older.isNotEmpty) _buildDateSection('Sebelumnya', older),
        ],
      ),
    );
  }

  Widget _buildDateSection(String label, List<_NotificationItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
        ...items.map((item) => _buildNotificationCard(item)),
      ],
    );
  }

  Widget _buildNotificationCard(_NotificationItem item) {
    return Dismissible(
      key: Key('${item.title}${item.time}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() {
          _allNotifications.remove(item);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: item.isRead
              ? Border.all(color: const Color(0xFFF1F5F9))
              : Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (!item.isRead) {
              setState(() => item.isRead = true);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: item.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                fontSize: 14,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3B82F6),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: item.isRead
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF475569),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTime(item.time),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari yang lalu';
  }
}

class _NotificationItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final DateTime time;
  final String type;
  bool isRead;

  _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}
