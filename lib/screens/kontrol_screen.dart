import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../core/config/app_config.dart';
import '../service/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_confirmation_dialog.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_loading_view.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_state_view.dart';
import '../widgets/app_surface.dart';

class KontrolScreen extends StatefulWidget {
  const KontrolScreen({super.key, required this.isActive});

  final bool isActive;

  @override
  State<KontrolScreen> createState() => _KontrolScreenState();
}

class _KontrolScreenState extends State<KontrolScreen> {
  bool pemanas = false;
  bool kipas = false;
  bool exhaust = false;
  bool isLoading = true;
  bool isSubmitting = false;
  String mode = 'MANUAL';
  String? errorMsg;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncPolling();
  }

  @override
  void didUpdateWidget(covariant KontrolScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncPolling();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncPolling() {
    if (widget.isActive) {
      _timer ??= Timer.periodic(AppConfig.dashboardPollingInterval, (timer) {
        if (mounted && !isSubmitting) {
          _loadStatus(showLoading: false);
        }
      });
      _loadStatus();
      return;
    }

    _timer?.cancel();
    _timer = null;
  }

  Future<void> _loadStatus({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        isLoading = true;
        errorMsg = null;
      });
    }

    try {
      final status = await ApiService.getActuatorStatus();
      setState(() {
        pemanas = status['heater'] == true;
        kipas = status['kipas'] == true;
        exhaust = status['exhaust'] == true;
        mode = status['mode']?.toString() ?? 'MANUAL';
        isLoading = false;
        errorMsg = null;
      });
    } catch (e) {
      setState(() {
        errorMsg = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _setMode(String newMode) async {
    if (isSubmitting || mode == newMode) return;
    setState(() => isSubmitting = true);
    try {
      final status = await ApiService.setDeviceMode(newMode);
      setState(() {
        mode = status['mode']?.toString() ?? newMode;
      });
      _showMessage('Mode device diubah ke $mode', const Color(0xFF2E7D32));
    } catch (e) {
      _showMessage(e.toString().replaceAll('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> _toggleActuator(String actuator, bool currentValue) async {
    if (isSubmitting || (mode == 'AUTO')) return;
    HapticFeedback.lightImpact();
    setState(() => isSubmitting = true);
    try {
      await ApiService.setActuator(actuator, !currentValue);
      await _loadStatus(showLoading: false);
      _showMessage(
        '${_labelFor(actuator)} ${!currentValue ? 'diaktifkan' : 'dimatikan'}',
        const Color(0xFF2E7D32),
      );
    } catch (e) {
      _showMessage(e.toString().replaceAll('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Future<void> _confirmModeChange(String newMode) async {
    if (isSubmitting || mode == newMode) return;
    HapticFeedback.lightImpact();

    final confirmed = await _showConfirmationDialog(
      icon: newMode == 'AUTO' ? Icons.autorenew_rounded : Icons.touch_app_rounded,
      accentColor: newMode == 'AUTO' ? AppTheme.info : AppTheme.success,
      title: 'Ubah mode device?',
      message:
          'Mode akan diubah ke $newMode. ${newMode == 'AUTO' ? 'Kontrol manual aktuator akan dinonaktifkan.' : 'Operator akan dapat mengendalikan aktuator secara manual.'}',
      confirmLabel: 'Ya, ubah mode',
    );

    if (confirmed == true) {
      await _setMode(newMode);
    }
  }

  Future<void> _confirmToggleActuator(
    String actuator,
    bool currentValue,
    Color accentColor,
  ) async {
    if (isSubmitting || mode == 'AUTO') return;

    final label = _labelFor(actuator);
    final nextStateLabel = currentValue ? 'matikan' : 'aktifkan';

    final confirmed = await _showConfirmationDialog(
      icon: _iconForActuator(actuator),
      accentColor: accentColor,
      title: '$nextStateLabel ${label.toLowerCase()}?',
      message:
          'Perintah ini akan ${currentValue ? 'menonaktifkan' : 'mengaktifkan'} $label pada device pengering kopi.',
      confirmLabel: 'Ya, lanjutkan',
    );

    if (confirmed == true) {
      await _toggleActuator(actuator, currentValue);
    }
  }

  IconData _iconForActuator(String actuator) {
    switch (actuator) {
      case 'heater':
        return Icons.local_fire_department;
      case 'kipas':
        return Icons.wind_power;
      default:
        return Icons.mode_fan_off;
    }
  }

  Future<bool?> _showConfirmationDialog({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return AppConfirmationDialog.show(
      context,
      icon: icon,
      accentColor: accentColor,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
    );
  }

  void _showMessage(String message, Color color) {
    if (color == Colors.red || color == AppTheme.danger) {
      AppFeedback.showError(context, message);
      return;
    }
    AppFeedback.showSuccess(context, message);
  }

  String _labelFor(String actuator) {
    switch (actuator) {
      case 'heater':
        return 'Heater';
      case 'kipas':
        return 'Kipas';
      default:
        return 'Exhaust';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: isLoading
            ? const AppLoadingView(label: 'Memuat status kontrol...')
            : errorMsg != null
            ? AppStateView(
                icon: Icons.settings_input_antenna,
                title: 'Kontrol perangkat belum tersedia',
                message: errorMsg!,
                actionLabel: 'Coba lagi',
                onAction: _loadStatus,
                iconColor: AppTheme.danger,
              )
            : RefreshIndicator(
                onRefresh: () async {
                  HapticFeedback.lightImpact();
                  await _loadStatus();
                },
                color: AppTheme.primary,
                backgroundColor: AppTheme.surface,
                child: ListView(
                  children: [
                    _buildHeader(),
                    _buildModeCard(),
                    _buildRingkasanStatus(),
                    _buildKartuKontrol(
                      nama: 'Heater',
                      deskripsi: 'Elemen pemanas ruang pengering',
                      icon: Icons.local_fire_department,
                      aktif: pemanas,
                      warnaAktif: Colors.red,
                      actuator: 'heater',
                    ),
                    _buildKartuKontrol(
                      nama: 'Kipas',
                      deskripsi: 'Sirkulasi udara ruang pengering',
                      icon: Icons.wind_power,
                      aktif: kipas,
                      warnaAktif: const Color(0xFF1565C0),
                      actuator: 'kipas',
                    ),
                    _buildKartuKontrol(
                      nama: 'Exhaust',
                      deskripsi: 'Pembuangan uap udara dari ruang pengering',
                      icon: Icons.mode_fan_off,
                      aktif: exhaust,
                      warnaAktif: const Color(0xFF6A1B9A),
                      actuator: 'exhaust',
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return AppPageHeader(
      center: const AtmaHeaderLogo(),
    );
  }

  Widget _buildModeCard() {
    final isAuto = mode == 'AUTO';
    return Container(
      margin: const EdgeInsets.all(16),
      child: AppSurface(
        radius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          AppSectionTitle(
            title: 'Mode Device',
            subtitle:
                'Pilih operasi otomatis dari backend atau kontrol manual dari operator.',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isAuto ? AppTheme.info : AppTheme.success)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isAuto ? 'AUTO aktif' : 'MANUAL aktif',
                style: TextStyle(
                  color: isAuto ? AppTheme.info : AppTheme.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saat mode AUTO aktif, kontrol manual dinonaktifkan di aplikasi.',
            style: TextStyle(
              color: isAuto ? AppTheme.info : AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () => _confirmModeChange('MANUAL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isAuto
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE8F5E9),
                  ),
                  child: Text(
                    'MANUAL',
                    style: TextStyle(
                      color: !isAuto ? Colors.white : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () => _confirmModeChange('AUTO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAuto
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE8F5E9),
                  ),
                  child: Text(
                    'AUTO',
                    style: TextStyle(
                      color: isAuto ? Colors.white : const Color(0xFF2E7D32),
                    ),
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

  Widget _buildKartuKontrol({
    required String nama,
    required String deskripsi,
    required IconData icon,
    required bool aktif,
    required Color warnaAktif,
    required String actuator,
  }) {
    final manualAllowed = mode != 'AUTO';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AppSurface(
        radius: 22,
        backgroundColor:
            aktif ? warnaAktif.withValues(alpha: 0.08) : AppTheme.surface,
        borderColor: aktif ? warnaAktif.withValues(alpha: 0.3) : null,
        child: Column(
          children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: aktif
                      ? warnaAktif.withValues(alpha: 0.12)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: aktif ? warnaAktif : const Color(0xFF9E9E9E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      deskripsi,
                      style: const TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: aktif,
                onChanged: (!manualAllowed || isSubmitting)
                    ? null
                    : (_) => _confirmToggleActuator(
                        actuator,
                        aktif,
                        warnaAktif,
                      ),
                activeThumbColor: warnaAktif,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: warnaAktif.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  aktif ? 'Sedang aktif' : 'Sedang nonaktif',
                  style: TextStyle(
                    color: warnaAktif,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  manualAllowed
                      ? 'Operator dapat mengubah status perangkat ini.'
                      : 'Perangkat dikunci oleh mode AUTO.',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (!manualAllowed || isSubmitting)
                  ? null
                  : () => _confirmToggleActuator(
                      actuator,
                      aktif,
                      warnaAktif,
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: aktif ? warnaAktif : const Color(0xFFF5F5F5),
                foregroundColor: aktif ? Colors.white : const Color(0xFF424242),
              ),
              child: Text(
                isSubmitting
                    ? 'Mengirim...'
                    : (aktif ? 'Matikan $nama' : 'Aktifkan $nama'),
              ),
            ),
          ),
          if (!manualAllowed) ...[
            const SizedBox(height: 10),
            const Text(
              'Kontrol manual dinonaktifkan saat mode AUTO.',
              style: TextStyle(color: Color(0xFF757575), fontSize: 12),
            ),
          ],
          ],
        ),
      ),
    );
  }

  Widget _buildRingkasanStatus() {
    final items = [
      {'nama': 'Heater', 'aktif': pemanas},
      {'nama': 'Kipas', 'aktif': kipas},
      {'nama': 'Exhaust', 'aktif': exhaust},
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      child: AppSurface(
        radius: 22,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(
            title: 'Ringkasan Status',
            subtitle: 'Snapshot cepat kondisi seluruh aktuator saat ini.',
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['nama'] as String,
                    style: const TextStyle(
                      color: Color(0xFF424242),
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (item['aktif'] as bool)
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (item['aktif'] as bool) ? 'ON' : 'OFF',
                      style: TextStyle(
                        color: (item['aktif'] as bool)
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF757575),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
