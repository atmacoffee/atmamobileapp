import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../core/config/app_config.dart';
import '../service/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loading_view.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_state_view.dart';
import '../widgets/app_surface.dart';

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key, required this.isActive});

  final bool isActive;

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  double suhu = 0;
  double kelembaban = 0;
  bool deviceOnline = false;
  String errorMsg = '';

  List<FlSpot> suhuSpots = [];
  List<FlSpot> kelembabanSpots = [];
  List<String> waktuLabels = [];

  bool isLoading = true;
  String waktuUpdate = "--:--:--";
  DateTime? createdAt;
  DateTime? monitoringStartedAt;
  Timer? _fetchTimer;
  Timer? _tickerTimer;

  int chartIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadHistoryReference();
    _syncPolling();
  }

  @override
  void didUpdateWidget(covariant SensorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncPolling();
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  void _syncPolling() {
    if (widget.isActive) {
      _fetchTimer ??= Timer.periodic(
        AppConfig.dashboardPollingInterval,
        (timer) => fetchData(),
      );
      _tickerTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || isLoading || errorMsg.isNotEmpty) {
          return;
        }
        setState(() {});
      });
      fetchData();
      return;
    }

    _stopPolling();
  }

  void _stopPolling() {
    _fetchTimer?.cancel();
    _tickerTimer?.cancel();
    _fetchTimer = null;
    _tickerTimer = null;
  }

  Future<void> _loadHistoryReference() async {
    try {
      final firstSensor = await ApiService.getFirstSensor();
      if (!mounted || firstSensor == null || firstSensor["createdAt"] == null) {
        return;
      }

      setState(() {
        monitoringStartedAt = _parseServerTime(firstSensor["createdAt"]);
      });
    } catch (e) {
      debugPrint("Load sensor history reference error: $e");
    }
  }

  void fetchData() async {
    try {
      final data = await ApiService.getLatestSensor();
      final status = await ApiService.getDeviceStatus();

      if (!mounted) return;

      final latestCreatedAt =
          data["createdAt"] != null
              ? _parseServerTime(data["createdAt"])
              : null;

      setState(() {
        suhu = (data["suhu"] as num?)?.toDouble() ?? 0;
        kelembaban = (data["kelembaban"] as num?)?.toDouble() ?? 0;
        deviceOnline = status["online"] == true;
        createdAt = latestCreatedAt;

        if (createdAt != null) {
          waktuUpdate = "${_formatWibTime(createdAt!)} WIB";

          suhuSpots.add(FlSpot(chartIndex.toDouble(), suhu));
          kelembabanSpots.add(FlSpot(chartIndex.toDouble(), kelembaban));

          waktuLabels.add(_formatWibTime(createdAt!));

          chartIndex++;

          if (suhuSpots.length > 10) {
            suhuSpots.removeAt(0);
            kelembabanSpots.removeAt(0);
            waktuLabels.removeAt(0);
          }
        } else {
          waktuUpdate = "--:--:--";
        }

        isLoading = false;
        errorMsg = '';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMsg = e.toString().replaceAll("Exception: ", "");
      });
    }
  }

  String getKalibrasiText() {
    if (monitoringStartedAt == null) {
      return "-";
    }

    final sekarang = DateTime.now().toUtc();
    final selisih = sekarang.difference(monitoringStartedAt!);

    int jam = selisih.inHours;
    int menit = selisih.inMinutes % 60;

    return "$jam Jam $menit Menit Lalu";
  }

  String getStatusSuhu() {
    if (suhu < 50) return "Di Bawah Ideal";
    if (suhu <= 55) return "Ideal";
    return "Di Atas Ideal";
  }

  Color getColorSuhu() {
    if (suhu >= 50 && suhu <= 55) return const Color(0xFF2E7D32);
    return Colors.red;
  }

  String getStatusKelembaban() {
    if (kelembaban <= 60) return "Dalam Batas";
    return "Melebihi Batas";
  }

  Color getColorKelembaban() {
    if (kelembaban <= 60) return const Color(0xFF1565C0);
    return Colors.red;
  }

  DateTime _parseServerTime(dynamic rawValue) {
    return DateTime.parse(rawValue.toString()).toUtc();
  }

  String _formatWibTime(DateTime utcTime) {
    final wibTime = utcTime.toUtc().add(const Duration(hours: 7));
    return "${wibTime.hour.toString().padLeft(2, '0')}:"
        "${wibTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: isLoading
            ? const AppLoadingView(label: 'Memuat data sensor...')
            : errorMsg.isNotEmpty
            ? AppStateView(
                icon: Icons.sensors_off_outlined,
                title: 'Data sensor gagal dimuat',
                message: errorMsg,
                actionLabel: 'Coba lagi',
                onAction: fetchData,
                iconColor: AppTheme.danger,
              )
            : createdAt == null
            ? const AppStateView(
                icon: Icons.query_stats,
                title: 'Belum ada data sensor',
                message:
                    'Perangkat belum mengirim pembacaan terbaru yang valid. Cek koneksi device dan coba lagi sebentar lagi.',
              )
            : ListView(
                children: [
                  buildHeader(),
                  const SizedBox(height: 16),
                  buildBannerPeringatan(),
                  buildStatusRingkas(),
                  buildSensorCard(
                    label: "Suhu Ruangan",
                    value: "${suhu.toStringAsFixed(0)}°C",
                    ideal: "Ideal: 50 - 55°C",
                    status: getStatusSuhu(),
                    statusColor: getColorSuhu(),
                    progress: (suhu / 60).clamp(0.0, 1.0),
                    color: Colors.red,
                    icon: Icons.thermostat,
                  ),
                  buildSensorCard(
                    label: "Kelembaban Udara",
                    value: "${kelembaban.toStringAsFixed(0)}%",
                    ideal: "Batas Maksimum: 60%",
                    status: getStatusKelembaban(),
                    statusColor: getColorKelembaban(),
                    progress: (kelembaban / 100).clamp(0.0, 1.0),
                    color: const Color(0xFF1565C0),
                    icon: Icons.water_drop,
                  ),
                  buildChart(),
                  buildHumidityChart(),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  Widget buildHeader() {
    return AppPageHeader(
      center: const AtmaHeaderLogo(),
    );
  }

  Widget buildStatusRingkas() {
    final items = [
      {
        'label': 'Device',
        'value': deviceOnline ? 'Online' : 'Offline',
        'active': deviceOnline,
      },
      {
        'label': 'Sensor Suhu & Kelembaban',
        'value': 'Aktif',
        'active': true,
      },
      {'label': 'Update', 'value': waktuUpdate, 'active': createdAt != null},
      {
        'label': 'Kalibrasi',
        'value': getKalibrasiText(),
        'active': createdAt != null,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: AppSurface(
        radius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const AppSectionTitle(
            title: 'Ringkasan Monitoring',
            subtitle: 'Kondisi sensor, device, dan waktu pembaruan terbaru.',
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['label']! as String,
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
                      color: (item['active']! as bool)
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item['value']! as String,
                      style: TextStyle(
                        color: (item['active']! as bool)
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

  Widget buildSensorCard({
    required String label,
    required String value,
    required String ideal,
    required String status,
    required Color statusColor,
    required double progress,
    required Color color,
    required IconData icon,
  }) {
    final isHighlighted = progress >= 0.7;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AppSurface(
        radius: 22,
        backgroundColor:
            isHighlighted ? color.withValues(alpha: 0.08) : AppTheme.surface,
        borderColor: isHighlighted ? color.withValues(alpha: 0.35) : null,
        child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? color.withValues(alpha: 0.12)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isHighlighted ? color : const Color(0xFF9E9E9E),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ideal,
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFEEEEEE),
                    color: color,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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

  Widget buildChart() {
    return _buildChartCard(
      title: 'Suhu Ruangan',
      subtitle: 'Realtime dari database sensor',
      badgeLabel: 'Ideal 50-55°C',
      badgeColor: AppTheme.success,
      spots: suhuSpots,
      maxY: 120,
      lineColor: AppTheme.success,
    );
  }

  Widget buildHumidityChart() {
    return _buildChartCard(
      title: 'Kelembaban Ruangan',
      subtitle: 'Realtime dari database sensor',
      badgeLabel: 'Batas <= 60%',
      badgeColor: AppTheme.info,
      spots: kelembabanSpots,
      maxY: 100,
      lineColor: AppTheme.info,
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required String badgeLabel,
    required Color badgeColor,
    required List<FlSpot> spots,
    required double maxY,
    required Color lineColor,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: AppSurface(
        radius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionTitle(
              title: title,
              subtitle: subtitle,
              trailing: _chartBadge(badgeLabel, badgeColor),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxY,
                    minX: 0,
                    maxX: spots.isEmpty ? 0 : (spots.length - 1).toDouble(),
                    clipData: FlClipData.all(),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(color: AppTheme.border, strokeWidth: 1),
                      getDrawingVerticalLine: (value) =>
                          FlLine(color: AppTheme.border.withValues(alpha: 0.6)),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < waktuLabels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  waktuLabels[index],
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: lineColor,
                        barWidth: 3.2,
                        dotData: FlDotData(show: spots.length <= 12),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              lineColor.withValues(alpha: 0.22),
                              lineColor.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget buildBannerPeringatan() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCC02)),
      ),
      child: Row(
        children: const [
          Icon(Icons.notifications_active, color: Color(0xFFE65100), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Batas Peringatan Aktif",
                  style: TextStyle(
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Notifikasi akan dikirim jika suhu di bawah 50°C, suhu di atas 55°C, atau kelembaban melebihi 60%.",
                  style: TextStyle(color: Color(0xFF757575), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
