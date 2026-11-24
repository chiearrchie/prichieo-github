import 'dart:convert';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const String _historyKey = 'prichieo.history.v1';
const String _unitKey = 'prichieo.unit.v1';
const String _percentKey = 'prichieo.modalPercent.v1';
const String _inputsKey = 'prichieo.inputs.v1';
const String _inNama = 'hpp.nama';
const String _inBahan = 'hpp.bahan';
const String _inTenaga = 'hpp.tenaga';
const String _inOverhead = 'hpp.overhead';
const String _inKemasan = 'hpp.kemasan';
const String _inHarga = 'hpp.harga';
const String _inPlatform = 'hpp.platform';
const String _inQty = 'hpp.qty';
const String _inOmset = 'kas.omset';
const String _inTarget = 'target.omset';
const String _inTargetHarga = 'target.harga';
const int _maxHistory = 50;
const String _instagramUrl = 'https://www.instagram.com/chiearrchie';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppData.instance.load();
  runApp(const PrichieoApp());
}

class PrichieoApp extends StatelessWidget {
  const PrichieoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRICHIEO - Smart Tools for Small Business',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainDashboard(),
    );
  }
}

class AppData {
  AppData._();

  static final AppData instance = AppData._();

  SharedPreferences? _prefs;
  Map<String, String> _inputs = <String, String>{};
  final ValueNotifier<String> unit = ValueNotifier<String>('unit');
  final ValueNotifier<String> modalPercent = ValueNotifier<String>('60');
  final ValueNotifier<List<HistoryEntry>> history =
      ValueNotifier<List<HistoryEntry>>(<HistoryEntry>[]);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      unit.value = _prefs!.getString(_unitKey) ?? 'unit';
      modalPercent.value = _prefs!.getString(_percentKey) ?? '60';
      final rawInputs = _prefs!.getString(_inputsKey);
      if (rawInputs != null && rawInputs.isNotEmpty) {
        final decoded = jsonDecode(rawInputs) as Map<String, dynamic>;
        _inputs = decoded.map(
          (String key, dynamic value) => MapEntry<String, String>(key, value.toString()),
        );
      }
      final raw = _prefs!.getStringList(_historyKey) ?? <String>[];
      history.value = raw
          .map((item) => HistoryEntry.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
      error.value = null;
    } catch (_) {
      error.value = 'Riwayat tidak dapat dimuat. Data baru tetap dipakai untuk sesi ini.';
    }
  }

  Future<bool> setUnit(String value) async {
    final cleaned = value.trim().isEmpty ? 'unit' : value.trim();
    if (unit.value == cleaned) return true;
    unit.value = cleaned;
    return _write(() => _prefs!.setString(_unitKey, cleaned));
  }

  Future<bool> setModalPercent(String value) async {
    final cleaned = value.trim().isEmpty ? '60' : value.trim();
    if (modalPercent.value == cleaned) return true;
    modalPercent.value = cleaned;
    return _write(() => _prefs!.setString(_percentKey, cleaned));
  }

  String getInput(String key) => _inputs[key] ?? '';

  Future<bool> setInput(String key, String value) async {
    if (_inputs[key] == value) return true;
    _inputs[key] = value;
    return _write(() => _prefs!.setString(_inputsKey, jsonEncode(_inputs)));
  }

  Future<bool> resetInputs() async {
    _inputs = <String, String>{};
    final savedInputs = await _write(() => _prefs!.remove(_inputsKey));
    final savedPercent = await setModalPercent('60');
    return savedInputs && savedPercent;
  }

  Future<bool> addHistory(HistoryEntry entry) async {
    final next = <HistoryEntry>[entry, ...history.value];
    if (next.length > _maxHistory) {
      next.removeRange(_maxHistory, next.length);
    }
    history.value = next;
    return _write(() => _prefs!.setStringList(
          _historyKey,
          next.map((item) => jsonEncode(item.toJson())).toList(),
        ));
  }

  Future<bool> clearHistory() async {
    history.value = <HistoryEntry>[];
    return _write(() => _prefs!.remove(_historyKey));
  }

  Future<bool> _write(Future<bool> Function() action) async {
    if (_prefs == null) {
      error.value = 'Penyimpanan lokal tidak tersedia.';
      return false;
    }
    try {
      final saved = await action();
      error.value = saved ? null : 'Penyimpanan lokal tidak tersedia.';
      return saved;
    } catch (_) {
      error.value = 'Penyimpanan lokal tidak tersedia.';
      return false;
    }
  }
}

class HistoryEntry {
  HistoryEntry({
    required this.id,
    required this.time,
    required this.title,
    required this.lines,
  });

  final String id;
  final DateTime time;
  final String title;
  final List<String> lines;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'time': time.toIso8601String(),
        'title': title,
        'lines': lines,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
      title: json['title'] as String? ?? 'Riwayat',
      lines: (json['lines'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

String rupiah(double value) {
  final rounded = value.round();
  final digits = rounded.abs().toString();
  const separator = '.';
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(separator);
    }
    buffer.write(digits[i]);
  }
  return '${rounded < 0 ? '-' : ''}Rp $buffer';
}

String persenTeks(double value) {
  final fixed = value.toStringAsFixed(1);
  if (fixed.endsWith('.0')) return fixed.substring(0, fixed.length - 2);
  return fixed.replaceAll('.', ',');
}

String ribuan(int value) {
  return value
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (match) => '${match[1]}.');
}

String savedOr(String key, String fallback) {
  final value = AppData.instance.getInput(key);
  return value.isEmpty ? fallback : value;
}

double angka(TextEditingController controller, [double fallback = 0]) {
  var text = controller.text.trim().replaceAll('Rp', '').replaceAll(' ', '');
  final lastComma = text.lastIndexOf(',');
  final lastDot = text.lastIndexOf('.');
  if (lastComma > lastDot) {
    text = text.replaceAll('.', '').replaceAll(',', '.');
  } else {
    text = text.replaceAll(',', '');
  }
  return double.tryParse(text) ?? fallback;
}

void beriTahu(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HppCalculatorScreen(),
    CashSplitterScreen(),
    TargetOmsetScreen(),
    HistoryScreen(),
    AboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 10,
        unselectedFontSize: 10,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'HPP',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Pemisah Kas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Target',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'About',
          ),
        ],
      ),
    );
  }
}

class PrichieoScaffold extends StatelessWidget {
  const PrichieoScaffold({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: <Widget>[
              Image.asset(
                'assets/logo-white.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                semanticLabel: '',
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Text(
                      'PRICHIEO',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'Manage Better, Grow Smarter.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
      body: body,
    );
  }
}

class HppCalculatorScreen extends StatefulWidget {
  const HppCalculatorScreen({super.key});

  @override
  State<HppCalculatorScreen> createState() => _HppCalculatorScreenState();
}

class _HppCalculatorScreenState extends State<HppCalculatorScreen> {
  final TextEditingController _namaCtrl =
      TextEditingController(text: AppData.instance.getInput(_inNama));
  final TextEditingController _satuanCtrl =
      TextEditingController(text: AppData.instance.unit.value);
  final TextEditingController _bahanCtrl =
      TextEditingController(text: AppData.instance.getInput(_inBahan));
  final TextEditingController _tenagaCtrl =
      TextEditingController(text: AppData.instance.getInput(_inTenaga));
  final TextEditingController _overheadCtrl =
      TextEditingController(text: AppData.instance.getInput(_inOverhead));
  final TextEditingController _kemasanCtrl =
      TextEditingController(text: AppData.instance.getInput(_inKemasan));
  final TextEditingController _hargaCtrl =
      TextEditingController(text: AppData.instance.getInput(_inHarga));
  final TextEditingController _platformCtrl =
      TextEditingController(text: savedOr(_inPlatform, '0'));
  final TextEditingController _qtyCtrl = TextEditingController(text: savedOr(_inQty, '1'));

  double _hpp = 0;
  String? _persenInfo;
  bool _updatingUnit = false;

  @override
  void initState() {
    super.initState();
    _bahanCtrl.addListener(_recalculate);
    _tenagaCtrl.addListener(_recalculate);
    _overheadCtrl.addListener(_recalculate);
    _kemasanCtrl.addListener(_recalculate);
    _hargaCtrl.addListener(_recalculate);
    _platformCtrl.addListener(_recalculate);
    _qtyCtrl.addListener(_recalculate);
    _namaCtrl.addListener(_saveInputs);
    _bahanCtrl.addListener(_saveInputs);
    _tenagaCtrl.addListener(_saveInputs);
    _overheadCtrl.addListener(_saveInputs);
    _kemasanCtrl.addListener(_saveInputs);
    _hargaCtrl.addListener(_saveInputs);
    _platformCtrl.addListener(_saveInputs);
    _qtyCtrl.addListener(_saveInputs);
    _satuanCtrl.addListener(_onSatuanEdited);
    AppData.instance.unit.addListener(_onUnitChanged);
    _recalculate(notify: false);
  }

  @override
  void dispose() {
    _bahanCtrl.removeListener(_recalculate);
    _tenagaCtrl.removeListener(_recalculate);
    _overheadCtrl.removeListener(_recalculate);
    _kemasanCtrl.removeListener(_recalculate);
    _hargaCtrl.removeListener(_recalculate);
    _platformCtrl.removeListener(_recalculate);
    _qtyCtrl.removeListener(_recalculate);
    _namaCtrl.removeListener(_saveInputs);
    _bahanCtrl.removeListener(_saveInputs);
    _tenagaCtrl.removeListener(_saveInputs);
    _overheadCtrl.removeListener(_saveInputs);
    _kemasanCtrl.removeListener(_saveInputs);
    _hargaCtrl.removeListener(_saveInputs);
    _platformCtrl.removeListener(_saveInputs);
    _qtyCtrl.removeListener(_saveInputs);
    _satuanCtrl.removeListener(_onSatuanEdited);
    AppData.instance.unit.removeListener(_onUnitChanged);
    for (final controller in <TextEditingController>[
      _namaCtrl,
      _satuanCtrl,
      _bahanCtrl,
      _tenagaCtrl,
      _overheadCtrl,
      _kemasanCtrl,
      _hargaCtrl,
      _platformCtrl,
      _qtyCtrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onSatuanEdited() {
    if (_updatingUnit) return;
    AppData.instance.setUnit(_satuanCtrl.text);
    _recalculate();
  }

  void _onUnitChanged() {
    final value = AppData.instance.unit.value;
    if (_satuanCtrl.text == value) return;
    _updatingUnit = true;
    _satuanCtrl.text = value;
    _updatingUnit = false;
    _recalculate();
  }

  void _saveInputs() {
    final data = AppData.instance;
    data.setInput(_inNama, _namaCtrl.text);
    data.setInput(_inBahan, _bahanCtrl.text);
    data.setInput(_inTenaga, _tenagaCtrl.text);
    data.setInput(_inOverhead, _overheadCtrl.text);
    data.setInput(_inKemasan, _kemasanCtrl.text);
    data.setInput(_inHarga, _hargaCtrl.text);
    data.setInput(_inPlatform, _platformCtrl.text);
    data.setInput(_inQty, _qtyCtrl.text);
  }

  void _recalculate({bool notify = true}) {
    final biaya = angka(_bahanCtrl) +
        angka(_tenagaCtrl) +
        angka(_overheadCtrl) +
        angka(_kemasanCtrl);
    final harga = angka(_hargaCtrl);
    final platform = angka(_platformCtrl).clamp(0.0, 100.0).toDouble();
    final qtyMentah = angka(_qtyCtrl, 1);
    final qty = qtyMentah <= 0 ? 1.0 : qtyMentah;
    final hasil = biaya / qty + harga * platform / 100;

    _hpp = hasil;
    if (harga > 0 && biaya + hasil > 0) {
      final persenMentah = hasil / harga * 100;
      _persenInfo = 'Persentase modal dari HPP: ${persenTeks(persenMentah)}%';
      AppData.instance.setModalPercent(persenTeks(persenMentah.clamp(0.0, 100.0)));
    } else {
      _persenInfo = null;
    }

    if (notify && mounted) setState(() {});
  }

  Future<void> _simpan() async {
    final nama = _namaCtrl.text.trim().isEmpty ? 'Produk' : _namaCtrl.text.trim();
    final saved = await AppData.instance.addHistory(
      HistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        time: DateTime.now(),
        title: 'HPP · $nama',
        lines: <String>[
          'Hasil: ${rupiah(_hpp)} per ${AppData.instance.unit.value}',
          'Bahan ${rupiah(angka(_bahanCtrl))} | Tenaga ${rupiah(angka(_tenagaCtrl))} | Overhead ${rupiah(angka(_overheadCtrl))}',
          'Kemasan ${rupiah(angka(_kemasanCtrl))} | Platform ${persenTeks(angka(_platformCtrl))}% | Qty ${persenTeks(angka(_qtyCtrl, 1))}',
        ],
      ),
    );
    if (!mounted) return;
    beriTahu(context, saved ? 'Hitungan HPP tersimpan di riwayat.' : 'Riwayat gagal disimpan.');
  }

  Widget _field(String label, TextEditingController controller, {bool decimal = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PrichieoScaffold(
      title: 'Kalkulator HPP',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Jangan menipu diri sendiri. Masukkan SEMUA biaya, sekecil apapun.',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: _namaCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Produk (opsional)',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: _satuanCtrl,
                decoration: InputDecoration(
                  labelText: 'Satuan Produk (contoh: porsi, biji, box)',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),
            ),
            _field('Total Biaya Bahan Baku (Rp)', _bahanCtrl),
            _field('Biaya Tenaga Kerja (Rp)', _tenagaCtrl),
            _field('Biaya Overhead / Lain-lain (Rp)', _overheadCtrl),
            _field('Total Biaya Kemasan (Rp)', _kemasanCtrl),
            _field('Harga Jual per Unit (Rp)', _hargaCtrl),
            _field('Potongan Platform (%)', _platformCtrl),
            _field('Jumlah Produk Dihasilkan', _qtyCtrl, decimal: false),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _simpan,
              child: const Text(
                'HITUNG HPP',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    'HPP per ${AppData.instance.unit.value}:',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rupiah(_hpp),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'JANGAN PERNAH JUAL DI BAWAH HARGA INI!',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
            if (_persenInfo != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _persenInfo!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CashSplitterScreen extends StatefulWidget {
  const CashSplitterScreen({super.key});

  @override
  State<CashSplitterScreen> createState() => _CashSplitterScreenState();
}

class _CashSplitterScreenState extends State<CashSplitterScreen> {
  final TextEditingController _omsetCtrl =
      TextEditingController(text: AppData.instance.getInput(_inOmset));
  final TextEditingController _persenCtrl =
      TextEditingController(text: AppData.instance.modalPercent.value);

  double _modal = 0;
  double _laba = 0;
  bool _updatingPercent = false;

  @override
  void initState() {
    super.initState();
    _omsetCtrl.addListener(_saveOmset);
    _persenCtrl.addListener(_onPercentEdited);
    AppData.instance.modalPercent.addListener(_onPercentChanged);
  }

  @override
  void dispose() {
    _omsetCtrl.removeListener(_saveOmset);
    _persenCtrl.removeListener(_onPercentEdited);
    AppData.instance.modalPercent.removeListener(_onPercentChanged);
    _omsetCtrl.dispose();
    _persenCtrl.dispose();
    super.dispose();
  }

  void _saveOmset() {
    AppData.instance.setInput(_inOmset, _omsetCtrl.text);
  }

  void _onPercentEdited() {
    if (_updatingPercent) return;
    AppData.instance.setModalPercent(_persenCtrl.text);
  }

  void _onPercentChanged() {
    final value = AppData.instance.modalPercent.value;
    if (_persenCtrl.text == value) return;
    _updatingPercent = true;
    _persenCtrl.text = value;
    _updatingPercent = false;
  }

  Future<void> _hitung() async {
    final omset = angka(_omsetCtrl);
    final persen = angka(_persenCtrl, 60).clamp(0.0, 100.0).toDouble();
    final modal = omset * persen / 100;

    setState(() {
      _modal = modal;
      _laba = omset - modal;
    });

    final saved = await AppData.instance.addHistory(
      HistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        time: DateTime.now(),
        title: 'Pemisah Kas',
        lines: <String>[
          'Omset ${rupiah(omset)} | Modal ${persenTeks(persen)}%',
          'Modal ${rupiah(modal)} | Laba ${rupiah(omset - modal)}',
        ],
      ),
    );
    if (!mounted) return;
    beriTahu(context, saved ? 'Pemisahan kas tersimpan di riwayat.' : 'Riwayat gagal disimpan.');
  }

  Widget _resultCard(String title, double amount, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        children: <Widget>[
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            rupiah(amount),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PrichieoScaffold(
      title: 'Pemisah Kas (Disiplin)',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Pisahkan hak bisnis Anda dari hak pribadi Anda. Segera pindahkan uang ke rekening yang berbeda setelah tutup buku harian.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _omsetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Omset / Pendapatan Hari Ini (Rp)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _persenCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Persentase HPP/Modal (%)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _hitung,
              child: const Text(
                'PISAHKAN UANG',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: _resultCard(
                    'UANG MODAL\n(Rekening Bisnis)',
                    _modal,
                    Colors.orange,
                    'Haram dipakai pribadi',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _resultCard(
                    'LABA KOTOR\n(Rekening Laba)',
                    _laba,
                    Colors.green,
                    'Untuk operasional & gaji',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TargetOmsetScreen extends StatefulWidget {
  const TargetOmsetScreen({super.key});

  @override
  State<TargetOmsetScreen> createState() => _TargetOmsetScreenState();
}

class _TargetOmsetScreenState extends State<TargetOmsetScreen> {
  final TextEditingController _targetCtrl =
      TextEditingController(text: AppData.instance.getInput(_inTarget));
  final TextEditingController _hargaCtrl =
      TextEditingController(text: AppData.instance.getInput(_inTargetHarga));
  int? _lastCount;

  @override
  void initState() {
    super.initState();
    _targetCtrl.addListener(_saveInputs);
    _hargaCtrl.addListener(_saveInputs);
    AppData.instance.unit.addListener(_onUnitChanged);
  }

  @override
  void dispose() {
    _targetCtrl.removeListener(_saveInputs);
    _hargaCtrl.removeListener(_saveInputs);
    AppData.instance.unit.removeListener(_onUnitChanged);
    _targetCtrl.dispose();
    _hargaCtrl.dispose();
    super.dispose();
  }

  void _saveInputs() {
    final data = AppData.instance;
    data.setInput(_inTarget, _targetCtrl.text);
    data.setInput(_inTargetHarga, _hargaCtrl.text);
  }

  void _onUnitChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _hitung() async {
    final target = angka(_targetCtrl);
    final harga = angka(_hargaCtrl);

    if (harga <= 0) {
      if (mounted) beriTahu(context, 'Isi harga jual per unit dengan angka lebih dari nol.');
      return;
    }

    final count = (target / harga).ceil();
    final unit = AppData.instance.unit.value;
    setState(() => _lastCount = count);

    final saved = await AppData.instance.addHistory(
      HistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        time: DateTime.now(),
        title: 'Target Penjualan',
        lines: <String>[
          'Target ${rupiah(target)} | Harga ${rupiah(harga)}',
          'Hasil: ${ribuan(count)} $unit',
        ],
      ),
    );
    if (!mounted) return;
    beriTahu(context, saved ? 'Target tersimpan di riwayat.' : 'Riwayat gagal disimpan.');
  }

  @override
  Widget build(BuildContext context) {
    return PrichieoScaffold(
      title: 'Target Penjualan',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Tentukan target omset harian Anda, lalu hitung berapa banyak produk yang HARUS terjual hari ini.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _targetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Omset Harian (Rp)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hargaCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga Jual per Unit (Rp)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _hitung,
              child: const Text(
                'HITUNG TARGET',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (_lastCount != null) ...<Widget>[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent),
                ),
                child: Column(
                  children: <Widget>[
                    const Text('Anda HARUS menjual minimal:', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      '$_lastCount ${AppData.instance.unit.value}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fokus jualan sampai angka ini tercapai!',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrichieoScaffold(
      title: 'Riwayat',
      body: ValueListenableBuilder<String?>(
        valueListenable: AppData.instance.error,
        builder: (context, error, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Text(error),
                  ),
                ValueListenableBuilder<List<HistoryEntry>>(
                  valueListenable: AppData.instance.history,
                  builder: (context, entries, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Expanded(
                              child: Text('Semua hitungan tersimpan di perangkat ini.'),
                            ),
                            TextButton(
                              onPressed: entries.isEmpty
                                  ? null
                                  : () async {
                                      final cleared = await AppData.instance.clearHistory();
                                      if (!context.mounted) return;
                                      beriTahu(
                                        context,
                                        cleared ? 'Riwayat dihapus.' : 'Riwayat gagal dihapus.',
                                      );
                                    },
                              child: const Text('HAPUS RIWAYAT'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (entries.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              children: <Widget>[
                                Text(
                                  'Belum ada riwayat',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Hitung HPP, pisahkan kas, atau tentukan target untuk mulai mencatat.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          ...entries.map((entry) => _entryCard(context, entry)),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _entryCard(BuildContext context, HistoryEntry entry) {
    final localizations = MaterialLocalizations.of(context);
    final time = entry.time.toLocal();
    final stamp = '${localizations.formatFullDate(time)} '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(time))}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text(
                  stamp,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...entry.lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  line,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _bukaInstagram(BuildContext context) async {
    final uri = Uri.parse(_instagramUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        beriTahu(context, 'Tautan Instagram tidak dapat dibuka.');
      }
    } catch (_) {
      if (context.mounted) beriTahu(context, 'Tautan Instagram tidak dapat dibuka.');
    }
  }

  Future<void> _resetInputs(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Kosongkan input?'),
        content: const Text(
          'Nama produk dan semua angka yang tersimpan akan dihapus. Persentase modal kembali ke 60. Riwayat dan satuan tidak berubah.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final ok = await AppData.instance.resetInputs();
    if (!context.mounted) return;
    beriTahu(context, ok ? 'Input berhasil dikosongkan.' : 'Input gagal dikosongkan.');
  }

  @override
  Widget build(BuildContext context) {
    return PrichieoScaffold(
      title: 'About',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/logo-white.png',
                          semanticLabel: '',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'PRICHIEO',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Manage Better, Grow Smarter.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const <Widget>[
                    _AboutRow(label: 'Nama aplikasi', value: 'PRICHIEO'),
                    _AboutRow(label: 'Kategori', value: 'Business / Productivity'),
                    _AboutRow(label: 'Short description', value: 'Smart Tools for Small Business'),
                    _AboutRow(label: 'Tagline', value: 'Manage Better, Grow Smarter.'),
                    _AboutRow(label: 'Developer', value: 'Created by Chiearrchie'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _bukaInstagram(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Buka Instagram @chiearrchie'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _resetInputs(context),
              icon: const Icon(Icons.restart_alt),
              label: const Text('KOSONGKAN INPUT'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
