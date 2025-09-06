import 'package:flutter/material.dart';
import 'package:couple_guard/modules/auth/src/models/family_model.dart';
import '../services/family_service.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:barcode_widget/barcode_widget.dart';

class FamilyScreen extends StatefulWidget {
  final String authToken;

  const FamilyScreen({Key? key, required this.authToken}) : super(key: key);

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final FamilyService _familyService = FamilyService();
  final TextEditingController _familyNameController = TextEditingController();

  bool _isLoading = false;

  // Data dummy untuk sementara
  // Gunakan Family, bukan FamilyModel
  List<GetFamily> _families = [];
  GetFamily fromFamily(Family family) {
    return GetFamily(
      id: family.id,
      name: family.name,
      familyCode: family.familyCode,
    );
  }

  // Buat kode acak 8 karakter

  @override
  void initState() {
    super.initState();
    _loadFamilies(); // load data saat pertama kali buka
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilies() async {
    setState(() => _isLoading = true);
    try {
      final families = await _familyService.getFamilies(
        authToken: widget.authToken,
      );
      setState(() {
        _families = families;
      });
    } catch (e) {
      debugPrint("❌ Error saat load families: $e");
      _showSnackBar("Gagal memuat data keluarga", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddFamilyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Tambah Keluarga Baru',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _familyNameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Keluarga',
                      labelStyle: TextStyle(color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primary.withOpacity(0.5),
                        ),
                      ),
                    ),
                    cursorColor: AppColors.primary,
                  ),
                  if (_isLoading) ...[
                    SizedBox(height: 16),
                    CircularProgressIndicator(color: AppColors.primary),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            Navigator.of(context).pop();
                            _familyNameController.clear();
                          },
                  child: Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      _isLoading ? null : () => _createFamily(setDialogState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isLoading ? 'Memproses...' : 'Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createFamily(StateSetter setDialogState) async {
    if (_familyNameController.text.trim().isEmpty) {
      _showSnackBar('Nama keluarga tidak boleh kosong', isError: true);
      return;
    }

    setDialogState(() {
      _isLoading = true;
    });

    try {
      final newFamilyResponse = await _familyService.createFamily(
        familyName: _familyNameController.text.trim(),
        authToken: widget.authToken,
      );

      setState(() {
        _families.insert(0, fromFamily(newFamilyResponse.family));
      });

      Navigator.of(context).pop();
      _familyNameController.clear();
      _showSnackBar('Keluarga berhasil ditambahkan!');
    } catch (e) {
      String errorMessage = 'Gagal menambahkan keluarga';

      if (e is FamilyException) {
        errorMessage = e.getUserFriendlyMessage();
      }

      _showSnackBar(errorMessage, isError: true);
    } finally {
      setDialogState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : AppColors.primary,
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Daftar Keluarga',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body:
          _isLoading
              ? _buildLoadingState() // 🔹 tampilkan loading dulu
              : _families.isEmpty
              ? _buildEmptyState()
              : _buildFamilyList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFamilyDialog,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Tambah Keluarga',
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            "Memuat data keluarga...",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom,
            size: 80,
            color: AppColors.primary.withOpacity(0.3),
          ),
          SizedBox(height: 16),
          Text(
            'Belum Ada Keluarga',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tambahkan keluarga pertama Anda!',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddFamilyDialog,
            icon: Icon(Icons.add, color: Colors.white),
            label: Text(
              'Tambah Keluarga',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyList() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        // Simulate refresh - dalam implementasi nyata, reload data dari API
        await Future.delayed(Duration(seconds: 1));
      },
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _families.length,
                itemBuilder: (context, index) {
                  final family = _families[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        radius: 25,
                        child: Icon(
                          Icons.family_restroom,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        family.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),

                      trailing: IconButton(
                        icon: Icon(Icons.qr_code, color: AppColors.primary),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                insetPadding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primary, // 🔹 base color
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // 🔹 Family name di luar background putih
                                          Text(
                                            family.name,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 16),

                                          // 🔹 Box putih untuk barcode
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: EdgeInsets.all(20),
                                            child: BarcodeWidget(
                                              barcode: Barcode.qrCode(),
                                              data: family.familyCode,
                                              width: 200,
                                              height: 200,
                                              drawText: false,
                                              backgroundColor: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 16),

                                          // 🔹 Tulisan instruksi di luar box putih
                                          Text(
                                            'Scan barcode ini untuk menghubungkan perangkat',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 🔹 Tombol close di pojok kanan atas
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
