import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../core/config/app_config.dart';
import '../service/api_service.dart';
import '../theme/app_theme.dart';
import 'notifikasi_screen.dart';
import '../widgets/app_loading_view.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_state_view.dart';
import '../widgets/app_surface.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.isActive});

  final bool isActive;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const int _maxChartPoints = 24;

  double suhu = 0;
  double kelembaban = 0;

  List<FlSpot> suhuSpots = [];
  List<FlSpot> kelembabanSpots = [];
  List<String> waktuLabels = [];

  bool heater = false;
  bool kipas = false;
  bool exhaust = false;
  bool deviceOnline = false;
  String mode = "MANUAL";
  int unreadCount = 0;

  DateTime? createdAt;
  DateTime? processStartedAt;

  bool isLoading = true;
  String? errorMsg;
  Timer? _fetchTimer;
  Timer? _tickerTimer;

  int chartIndex = 0;

  Future<void> loadChartHistory() async {
    try {
      final results = await Future.wait([
        ApiService.getRiwayatSensor(),
        ApiService.getFirstSensor(),
      ]);

      final riwayat = results[0] as List<dynamic>;
      final firstSensor = results[1] as Map<String, dynamic>?;
      final chartData = _buildChartData(riwayat);

      suhuSpots = chartData.spots;
      kelembabanSpots = chartData.humiditySpots;
      waktuLabels = chartData.labels;

      processStartedAt =
          firstSensor != null && firstSensor["createdAt"] != null
              ? _parseServerTime(firstSensor["createdAt"])
              : null;

      chartIndex = suhuSpots.length;

      setState(() {});
    } catch (e) {
      debugPrint("Load history error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadChartHistory();
    _syncPolling();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
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
        if (!mounted || isLoading || errorMsg != null) {
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

  void fetchData() async {
    try {
      final data = await ApiService.getLatestSensor();
      final deviceStatus = await ApiService.getDeviceStatus();
      final actuatorStatus = await ApiService.getActuatorStatus();
      final notifications = await ApiService.getUnreadNotificationCount();

      if (!mounted) return;

      setState(() {
        final latestCreatedAt =
            data["createdAt"] != null
                ? _parseServerTime(data["createdAt"])
                : null;

        suhu = (data["suhu"] as num?)?.toDouble() ?? 0;
        kelembaban = (data["kelembaban"] as num?)?.toDouble() ?? 0;
        heater = actuatorStatus["heater"] == true;
        kipas = actuatorStatus["kipas"] == true;
        exhaust = actuatorStatus["exhaust"] == true;
        mode = actuatorStatus["mode"]?.toString() ?? "MANUAL";
        deviceOnline = deviceStatus["online"] == true;
        unreadCount = notifications;
        createdAt = latestCreatedAt;

        // ================= GRAFIK REALTIME =================

        if (createdAt != null &&
            (suhuSpots.isEmpty || suhuSpots.last.y != suhu)) {
          suhuSpots.add(FlSpot(chartIndex.toDouble(), suhu));
          kelembabanSpots.add(FlSpot(chartIndex.toDouble(), kelembaban));

          waktuLabels.add(_formatWibTime(createdAt!));

          chartIndex++;

          if (suhuSpots.length > _maxChartPoints) {
            suhuSpots.removeAt(0);
            kelembabanSpots.removeAt(0);
            waktuLabels.removeAt(0);
            for (int i = 0; i < suhuSpots.length; i++) {
              suhuSpots[i] = FlSpot(i.toDouble(), suhuSpots[i].y);
              kelembabanSpots[i] = FlSpot(i.toDouble(), kelembabanSpots[i].y);
            }
            chartIndex = suhuSpots.length;
          }
        }

        isLoading = false;
        errorMsg = null;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMsg = e.toString();
      });
    }
  }

  // ================= DURASI =================

  Duration getDurasi() {
    if (processStartedAt == null) {
      return const Duration(hours: 0);
    }

    final sekarang = DateTime.now().toUtc();

    return sekarang.difference(processStartedAt!);
  }

  // ================= TEXT DURASI =================

  String getDurasiText() {
    final durasi = getDurasi();

    int jam = durasi.inHours;
    int menit = durasi.inMinutes % 60;

    return "$jam Jam $menit Menit";
  }

  // ================= STATUS HEATER =================

  String getStatusHeater() {
    if (heater) {
      return "Sedang Mengeringkan";
    }

    return "Heater Mati";
  }

  // ================= STATUS KIPAS =================

  String getStatusKipas() {
    if (kipas) {
      return "Membuang Uap Air";
    }

    return "Kipas Mati";
  }

  // ================= ESTIMASI =================

  String getEstimasiSelesai() {
    if (processStartedAt == null) {
      return "-";
    }

    // total waktu ideal pengeringan
    const totalJam = 72;

    // durasi berjalan
    final durasi = getDurasi();

    // hitung sisa waktu
    int sisaMenit = (totalJam * 60) - durasi.inMinutes;

    // kalau selesai
    if (sisaMenit <= 0) {
      return "Selesai";
    }

    int jam = sisaMenit ~/ 60;
    int menit = sisaMenit % 60;

    return "$jam Jam $menit Menit Lagi";
  }

  String getStartTimeText() {
    if (processStartedAt == null) {
      return "-";
    }

    return "Mulai "
        "${_formatWibTime(processStartedAt!)} WIB";
  }

  String getProgressText() {
    final progress = getProgress() * 100;

    if (progress <= 0) {
      return "0%";
    }
    if (progress < 1) {
      return "${progress.toStringAsFixed(1)}%";
    }
    return "${progress.toStringAsFixed(0)}%";
  }

  // ================= PROGRESS =================

  double getProgress() {
    if (processStartedAt == null) {
      return 0;
    }

    // total pengeringan ideal = 72 jam
    const int totalMenit = 72 * 60;

    // waktu sekarang
    final sekarang = DateTime.now().toUtc();

    // selisih waktu dari created_at
    final durasiBerjalan = sekarang.difference(processStartedAt!).inMinutes;

    // hitung progress
    double progress = durasiBerjalan / totalMenit;

    // batas maksimal 100%
    if (progress >= 1) {
      return 1;
    }

    // batas minimal 0%
    if (progress <= 0) {
      return 0;
    }

    return progress;
  }

  int getBottomTitleInterval() {
    if (waktuLabels.length <= 6) {
      return 1;
    }

    return (waktuLabels.length / 6).ceil();
  }

  _ChartData _buildChartData(List<dynamic> riwayat) {
    if (riwayat.isEmpty) {
      return const _ChartData(spots: [], humiditySpots: [], labels: []);
    }

    final ascending = riwayat.reversed.toList();
    final totalPoints = ascending.length;
    final step = totalPoints > _maxChartPoints
        ? (totalPoints / _maxChartPoints).ceil()
        : 1;

    final sampled = <dynamic>[];
    for (int i = 0; i < totalPoints; i += step) {
      sampled.add(ascending[i]);
    }

    if (sampled.isEmpty || sampled.last != ascending.last) {
      sampled.add(ascending.last);
    }

    final spots = <FlSpot>[];
    final humiditySpots = <FlSpot>[];
    final labels = <String>[];

    for (int i = 0; i < sampled.length; i++) {
      final item = sampled[i] as Map<String, dynamic>;
      final waktu = _parseServerTime(item["createdAt"]);

      spots.add(FlSpot(i.toDouble(), (item["suhu"] as num?)?.toDouble() ?? 0));
      humiditySpots.add(
        FlSpot(i.toDouble(), (item["kelembaban"] as num?)?.toDouble() ?? 0),
      );
      labels.add(_formatWibTime(waktu));
    }

    return _ChartData(
      spots: spots,
      humiditySpots: humiditySpots,
      labels: labels,
    );
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
            ? const AppLoadingView(label: 'Menyiapkan dashboard...')
            : (errorMsg != null)
            ? AppStateView(
                icon: Icons.cloud_off,
                title: 'Dashboard belum dapat dimuat',
                message: errorMsg!,
                actionLabel: 'Coba lagi',
                onAction: fetchData,
                iconColor: AppTheme.danger,
              )
            : ListView(
                children: [
                  buildHeader(),
                  buildTopCards(),
                  buildModeStatusCard(),
                  buildChart(),
                  buildHumidityChart(),
                  buildProgress(),
                  buildActivity(),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  // ================= HEADER =================

  Widget buildHeader() {
    return AppPageHeader(
      center: const AtmaHeaderLogo(),
      trailing: HeaderIconButton(
        icon: Icons.notifications,
        badge: unreadCount > 0
            ? (unreadCount > 9 ? '9+' : '$unreadCount')
            : null,
        onPressed: () {
          Navigator.push(
            context,
            _slideRoute(const NotifikasiScreen(), begin: const Offset(1, 0)),
          ).then((_) => fetchData());
        },
      ),
    );
  }

  PageRouteBuilder<void> _slideRoute(Widget page, {required Offset begin}) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(
          begin: begin,
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  // ================= CARD =================

  Widget buildTopCards() {
    final metrics = [
      (
        value: "${suhu.toStringAsFixed(1)}°C",
        title: "Suhu",
        color: Colors.red,
        icon: Icons.thermostat,
      ),
      (
        value: "${kelembaban.toStringAsFixed(1)}%",
        title: "Kelembaban",
        color: AppTheme.info,
        icon: Icons.water_drop,
      ),
      (
        value: getDurasiText(),
        title: "Durasi",
        color: AppTheme.warning,
        icon: Icons.timer_outlined,
      ),
      (
        value: getEstimasiSelesai(),
        title: "Estimasi",
        color: AppTheme.success,
        icon: Icons.schedule,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pemantauan kondisi pengeringan kopi secara real-time",
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),

          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: metrics.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.08,
            ),
            itemBuilder: (context, index) {
              final item = metrics[index];
              return card(item.value, item.title, item.color, item.icon);
            },
          ),
          const SizedBox(height: 12),
          AppSurface(
            radius: 24,
            backgroundColor: AppTheme.primaryStrong,
            borderColor: AppTheme.primaryStrong,
            child: Row(
              children: [
                Expanded(
                  child: _highlightMetric(
                    'Mode operasi',
                    mode,
                    mode == "AUTO" ? Icons.autorenew : Icons.touch_app,
                  ),
                ),
                Expanded(
                  child: _highlightMetric(
                    'Koneksi device',
                    deviceOnline ? 'Terhubung' : 'Offline',
                    deviceOnline ? Icons.wifi_tethering : Icons.wifi_off,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightMetric(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget card(String value, String title, Color color, IconData icon) {
    return AppSurface(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ================= ENVIRONMENT =================

  Widget buildModeStatusCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: AppSurface(
        radius: 24,
        child: Row(
          children: [
            Expanded(
              child: _modeStatusItem(
                Icons.local_fire_department,
                heater ? "Aktif" : "Mati",
                "Heater",
                heater ? Colors.red : Colors.grey,
                heater ? const Color(0xFFFFEBEE) : const Color(0xFFF5F5F5),
              ),
            ),
            Expanded(
              child: _modeStatusItem(
                Icons.wind_power,
                kipas ? "Aktif" : "Mati",
                "Kipas",
                kipas ? Colors.blue : Colors.grey,
                kipas ? const Color(0xFFE3F2FD) : const Color(0xFFF5F5F5),
              ),
            ),
            Expanded(
              child: _modeStatusItem(
                Icons.mode_fan_off,
                exhaust ? "Aktif" : "Mati",
                "Exhaust",
                exhaust ? const Color(0xFF6A1B9A) : Colors.grey,
                exhaust ? const Color(0xFFF3E5F5) : const Color(0xFFF5F5F5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeStatusItem(
    IconData icon,
    String value,
    String label,
    Color iconColor,
    Color bgColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 21),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11),
        ),
      ],
    );
  }

  // ================= GRAFIK =================

  Widget buildChart() {
    return _buildChartCard(
      title: "Grafik Suhu Hari Ini",
      subtitle: "Tren suhu ruang pengering dari pembacaan terbaru",
      badgeLabel: "Target 50-55°C",
      badgeColor: AppTheme.success,
      spots: suhuSpots,
      lineColor: AppTheme.success,
      maxY: 120,
    );
  }

  Widget buildHumidityChart() {
    return _buildChartCard(
      title: "Grafik Kelembaban Hari Ini",
      subtitle: "Pantau kestabilan kadar uap air ruang pengering",
      badgeLabel: "Batas <= 60%",
      badgeColor: AppTheme.info,
      spots: kelembabanSpots,
      lineColor: AppTheme.info,
      maxY: 100,
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required String badgeLabel,
    required Color badgeColor,
    required List<FlSpot> spots,
    required Color lineColor,
    required double maxY,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: AppSurface(
        radius: 24,
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
                          reservedSize: 34,
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
                            if (index >= 0 &&
                                index < waktuLabels.length &&
                                index % getBottomTitleInterval() == 0) {
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
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
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
                              lineColor.withValues(alpha: 0.24),
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

  // ================= PROGRESS =================

  Widget buildProgress() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: AppSurface(
        radius: 24,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Progress Pengeringan",
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: getProgress(),
              backgroundColor: const Color(0xFFE8F5E9),
              color: const Color(0xFF4CAF50),
              minHeight: 10,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getStartTimeText(),
                style: const TextStyle(color: Color(0xFF757575), fontSize: 12),
              ),

              Text(
                getProgressText(),
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  // ================= ACTIVITY =================

  Widget buildActivity() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: AppSurface(
        radius: 24,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Aktivitas Terbaru",
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          item(
            heater ? "Heater sedang mengeringkan kopi" : "Heater sedang mati",
          ),

          item(kipas ? "Kipas sedang membuang uap air" : "Kipas sedang mati"),

          item(exhaust ? "Exhaust aktif" : "Exhaust mati"),

          item("Suhu saat ini ${suhu.toStringAsFixed(1)}°C"),

          item("Kelembaban ${kelembaban.toStringAsFixed(1)}%"),
        ],
      ),
      ),
    );
  }

  Widget item(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF424242), fontSize: 13),
            ),
          ),

          Text(
            "${DateTime.now().hour}:${DateTime.now().minute}",
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final List<FlSpot> spots;
  final List<FlSpot> humiditySpots;
  final List<String> labels;

  const _ChartData({
    required this.spots,
    required this.humiditySpots,
    required this.labels,
  });
}
