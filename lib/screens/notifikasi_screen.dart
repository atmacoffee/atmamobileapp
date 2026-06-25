import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../service/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_loading_view.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_state_view.dart';
import '../widgets/app_surface.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _notifications = [];

  bool isLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  int unreadCount = 0;
  int currentPage = 0;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    refreshNotifications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> refreshNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      currentPage = 0;
      hasMore = true;
      _notifications.clear();
    });

    try {
      final unread = await ApiService.getUnreadNotificationCount();
      final notifications = await ApiService.getNotifications(page: 0);
      if (!mounted) return;
      setState(() {
        unreadCount = unread;
        _notifications.addAll(notifications);
        hasMore = notifications.length == 20;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (isLoadingMore || !hasMore || isLoading) return;
    setState(() => isLoadingMore = true);
    try {
      final nextPage = currentPage + 1;
      final notifications = await ApiService.getNotifications(page: nextPage);
      if (!mounted) return;
      setState(() {
        currentPage = nextPage;
        _notifications.addAll(notifications);
        hasMore = notifications.length == 20;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => hasMore = false);
    } finally {
      if (mounted) {
        setState(() => isLoadingMore = false);
      }
    }
  }

  Future<void> _markRead(Map<String, dynamic> notification) async {
    if (notification['read'] == true) return;
    try {
      final updated = await ApiService.markNotificationRead(
        (notification['id'] as num).toInt(),
      );
      if (!mounted) return;
      setState(() {
        final index = _notifications.indexWhere(
          (item) => item['id'] == updated['id'],
        );
        if (index >= 0) {
          _notifications[index] = updated;
        }
        unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
      });
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      if (!mounted) return;
      setState(() {
        unreadCount = 0;
        for (final notification in _notifications) {
          notification['read'] = true;
        }
      });
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    AppFeedback.showError(context, message);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 120) {
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? const AppLoadingView(label: 'Memuat notifikasi...')
                  : errorMessage != null
                  ? AppStateView(
                      icon: Icons.notifications_off_outlined,
                      title: 'Notifikasi gagal dimuat',
                      message: errorMessage!,
                      actionLabel: 'Muat ulang',
                      onAction: refreshNotifications,
                      iconColor: AppTheme.danger,
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        HapticFeedback.lightImpact();
                        await refreshNotifications();
                      },
                      color: AppTheme.primary,
                      backgroundColor: AppTheme.surface,
                      child: _notifications.isEmpty
                          ? LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: SizedBox(
                                    height: constraints.maxHeight,
                                    child: const AppStateView(
                                      icon: Icons.notifications_none,
                                      title: 'Belum ada notifikasi',
                                      message:
                                          'Semua alert dan informasi operasional akan muncul di sini.',
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView(
                              controller: _scrollController,
                              children: [
                                _buildSummaryPanel(),
                                ..._notifications.map(_buildNotificationItem),
                                if (isLoadingMore || hasMore) _buildLoadMoreHint(),
                              ],
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AppPageHeader(
      leading: HeaderIconButton(
        icon: Icons.arrow_back,
        onPressed: () => Navigator.maybePop(context),
      ),
      center: const Text(
        'Notifikasi',
        style: TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: IconButton(
        onPressed: unreadCount == 0 ? null : _markAllRead,
        icon: Icon(
          Icons.done_all,
          color: unreadCount == 0
              ? const Color(0xFFBDBDBD)
              : const Color(0xFF4CAF50),
        ),
      ),
    );
  }

  Widget _buildSummaryPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: AppSurface(
        radius: 24,
        backgroundColor: AppTheme.primaryStrong,
        borderColor: AppTheme.primaryStrong,
        child: Row(
          children: [
            Expanded(
              child: _summaryItem(
                'Belum dibaca',
                unreadCount.toString(),
                Icons.markunread_outlined,
              ),
            ),
            Expanded(
              child: _summaryItem(
                'Total dimuat',
                _notifications.length.toString(),
                Icons.inbox_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadMoreHint() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: isLoadingMore
            ? const CircularProgressIndicator()
            : const Text(
                'Scroll ke bawah untuk memuat notifikasi berikutnya.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final read = notification['read'] == true;
    final severity =
        notification['severity']?.toString().toUpperCase() ?? 'INFO';
    final color = _severityColor(severity);
    final createdAt = notification['createdAt']?.toString();

    return GestureDetector(
      onTap: () => _markRead(notification),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: AppSurface(
          radius: 22,
          borderColor: read ? null : color.withValues(alpha: 0.35),
          backgroundColor:
              read ? AppTheme.surface : color.withValues(alpha: 0.05),
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_severityIcon(severity), color: color),
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
                          _sanitizeNotificationText(
                            notification['title']?.toString(),
                          ),
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!read)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _sanitizeNotificationText(
                      notification['message']?.toString(),
                    ),
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          severity,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatNotificationTime(createdAt),
                          style: const TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 11,
                          ),
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
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'ERROR':
        return Colors.red;
      case 'WARNING':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF1565C0);
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'ERROR':
        return Icons.error_outline;
      case 'WARNING':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  String _formatNotificationTime(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return '-';
    }

    try {
      final localTime = DateTime.parse(rawValue).toLocal();
      final now = DateTime.now();
      final diff = now.difference(localTime);

      if (diff.inMinutes < 1) {
        return 'Baru saja';
      }
      if (diff.inHours < 1) {
        return '${diff.inMinutes} menit lalu';
      }
      if (diff.inDays < 1) {
        return '${diff.inHours} jam lalu';
      }
      if (diff.inDays < 7) {
        return '${diff.inDays} hari lalu';
      }

      return "${localTime.day.toString().padLeft(2, '0')}/"
          "${localTime.month.toString().padLeft(2, '0')}/"
          "${localTime.year} "
          "${localTime.hour.toString().padLeft(2, '0')}:"
          "${localTime.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return rawValue;
    }
  }

  String _sanitizeNotificationText(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    return value.replaceAll('Â°C', '°C').replaceAll('Â°', '°');
  }
}
