import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_confirmation_dialog.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_surface.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  String nama = "";
  String email = "";
  String lokasi = "Belum diisi";
  String jenisKopi = "Arabika";
  String namaAlat = "ATMA-01";
  String? editingField;
  bool isSaving = false;

  late final TextEditingController namaController;
  late final TextEditingController lokasiController;
  late final TextEditingController jenisKopiController;
  late final TextEditingController namaAlatController;

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(text: nama);
    lokasiController = TextEditingController(text: lokasi);
    jenisKopiController = TextEditingController(text: jenisKopi);
    namaAlatController = TextEditingController(text: namaAlat);
    loadProfil();
  }

  void loadProfil() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nama = prefs.getString('nama') ?? "Pengguna";
      email = prefs.getString('email') ?? "";
      lokasi = prefs.getString('lokasi') ?? "Belum diisi";
      jenisKopi = prefs.getString('jenis_kopi') ?? "Arabika";
      namaAlat = prefs.getString('nama_alat') ?? "ATMA-01";
    });
    namaController.text = nama;
    lokasiController.text = lokasi;
    jenisKopiController.text = jenisKopi;
    namaAlatController.text = namaAlat;

    try {
      final profile = await ApiService.getCurrentUser();
      if (!mounted) return;
      setState(() {
        nama = profile['nama']?.toString() ?? nama;
        email = profile['email']?.toString() ?? email;
        lokasi = profile['lokasi']?.toString() ?? lokasi;
        jenisKopi = profile['jenisKopi']?.toString() ?? jenisKopi;
        namaAlat = profile['namaAlat']?.toString() ?? namaAlat;
      });
      namaController.text = nama;
      lokasiController.text = lokasi;
      jenisKopiController.text = jenisKopi;
      namaAlatController.text = namaAlat;
    } catch (_) {}
  }

  @override
  void dispose() {
    namaController.dispose();
    lokasiController.dispose();
    jenisKopiController.dispose();
    namaAlatController.dispose();
    super.dispose();
  }

  String getInisial() {
    final parts = nama
        .trim()
        .split(" ")
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty || parts[0].isEmpty) {
      return "P";
    }
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  void simpanProfil() async {
    if (namaController.text.trim().isEmpty) {
      AppFeedback.showError(context, 'Nama wajib diisi');
      return;
    }

    setState(() => isSaving = true);
    try {
      final profile = await ApiService.updateCurrentUser(
        nama: namaController.text,
        lokasi: lokasiController.text,
        jenisKopi: jenisKopiController.text,
        namaAlat: namaAlatController.text,
      );
      if (!mounted) return;

      setState(() {
        nama = profile['nama']?.toString() ?? namaController.text;
        email = profile['email']?.toString() ?? email;
        lokasi = profile['lokasi']?.toString() ?? lokasiController.text;
        jenisKopi =
            profile['jenisKopi']?.toString() ?? jenisKopiController.text;
        namaAlat = profile['namaAlat']?.toString() ?? namaAlatController.text;
        editingField = null;
      });
      AppFeedback.showSuccess(context, 'Profil berhasil disimpan');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        e.toString().replaceAll("Exception: ", ""),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void keluar() {
    AppConfirmationDialog.show(
      context,
      icon: Icons.logout_rounded,
      accentColor: AppTheme.danger,
      title: 'Keluar dari akun?',
      message:
          'Anda akan keluar dari sesi saat ini dan perlu login kembali untuk mengakses monitoring serta kontrol perangkat.',
      confirmLabel: 'Keluar',
    ).then((confirmed) async {
      if (confirmed != true || !mounted) return;
      await ApiService.logout();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  void mulaiEdit(String field) {
    _resetController(field);
    setState(() => editingField = field);
  }

  void batalEdit(String field) {
    _resetController(field);
    setState(() => editingField = null);
  }

  void _resetController(String field) {
    switch (field) {
      case 'nama':
        namaController.text = nama;
        break;
      case 'lokasi':
        lokasiController.text = lokasi;
        break;
      case 'jenisKopi':
        jenisKopiController.text = jenisKopi;
        break;
      case 'namaAlat':
        namaAlatController.text = namaAlat;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          children: [
            const AppPageHeader(
              center: AtmaHeaderLogo(),
            ),
            buildAvatar(),
            buildInfoKebun(),
            buildTombolKeluar(),
            buildFooter(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget buildAvatar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AppSurface(
        radius: 28,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        backgroundColor: AppTheme.primaryStrong,
        borderColor: AppTheme.primaryStrong,
        child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: Center(
                  child: Text(
                    getInisial(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            nama,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email.isEmpty ? "Petani Kopi · ATMA" : email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: buildBadge(
                  Icons.location_on,
                  lokasi,
                  AppTheme.surface,
                  Colors.white.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: buildBadge(
                  Icons.coffee,
                  jenisKopi,
                  AppTheme.surface,
                  Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _heroInfo('Alat aktif', namaAlat)),
              const SizedBox(width: 10),
              Expanded(child: _heroInfo('Tipe kopi', jenisKopi)),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _heroInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBadge(IconData icon, String label, Color warna, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: warna.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: warna, size: 13),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: warna,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoKebun() {
    final items = [
      {
        "key": "nama",
        "label": "Nama Petani",
        "value": nama,
        "icon": Icons.person,
        "warna": const Color(0xFF2E7D32),
        "bgColor": const Color(0xFFE8F5E9),
        "controller": namaController,
      },
      {
        "key": "lokasi",
        "label": "Lokasi Kebun",
        "value": lokasi,
        "icon": Icons.location_on,
        "warna": const Color(0xFF1565C0),
        "bgColor": const Color(0xFFE3F2FD),
        "controller": lokasiController,
      },
      {
        "key": "jenisKopi",
        "label": "Jenis Kopi",
        "value": jenisKopi,
        "icon": Icons.coffee,
        "warna": const Color(0xFFE65100),
        "bgColor": const Color(0xFFFFF3E0),
        "controller": jenisKopiController,
      },
      {
        "key": "namaAlat",
        "label": "Nama Alat",
        "value": namaAlat,
        "icon": Icons.precision_manufacturing,
        "warna": const Color(0xFF6A1B9A),
        "bgColor": const Color(0xFFF3E5F5),
        "controller": namaAlatController,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(
            title: 'Informasi Kebun',
            subtitle: 'Data operator dan perangkat yang bisa diperbarui dari aplikasi.',
          ),
          const SizedBox(height: 10),
          ...items.map((item) {
            final key = item["key"] as String;
            final isItemEditing = editingField == key;
            final canEdit =
                !isSaving && (editingField == null || isItemEditing);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: AppSurface(
                radius: 20,
                padding: const EdgeInsets.all(14),
                child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item["bgColor"] as Color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item["icon"] as IconData,
                      color: item["warna"] as Color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["label"] as String,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        isItemEditing
                            ? TextField(
                                controller:
                                    item["controller"] as TextEditingController,
                                enabled: !isSaving,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                              )
                            : Text(
                                item["value"] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isItemEditing)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _profileActionButton(
                          icon: Icons.close,
                          color: Colors.red,
                          onTap: isSaving ? null : () => batalEdit(key),
                        ),
                        const SizedBox(width: 6),
                        _profileActionButton(
                          icon: isSaving ? Icons.hourglass_top : Icons.check,
                          color: const Color(0xFF2E7D32),
                          onTap: isSaving ? null : simpanProfil,
                        ),
                      ],
                    )
                  else
                    _profileActionButton(
                      icon: Icons.edit,
                      color: canEdit
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFBDBDBD),
                      onTap: canEdit ? () => mulaiEdit(key) : null,
                    ),
                ],
              ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _profileActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: onTap == null ? 0.06 : 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Widget buildTombolKeluar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GestureDetector(
        onTap: keluar,
        child: AppSurface(
          radius: 20,
          backgroundColor: AppTheme.danger.withValues(alpha: 0.05),
          borderColor: AppTheme.danger.withValues(alpha: 0.18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text(
                    "Keluar",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFooter() {
    final year = DateTime.now().year;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.copyright, size: 12, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            "$year ATMA TECH - Smart Coffe Dryer",
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
