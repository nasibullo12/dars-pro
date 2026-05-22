import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import 'jadval_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    DataService.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    await DataService.load();
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    DataService.removeListener(_onDataChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('Dars', style: TextStyle(color: AppTheme.orange)),
            Text(' Pro'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.muted),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Jadval'),
            Tab(text: 'Statistika'),
            Tab(text: 'Shogirdlar'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.orange))
          : TabBarView(
              controller: _tabController,
              children: const [
                JadvalScreen(),
                StatsScreen(),
                StudentsListScreen(),
              ],
            ),
    );
  }
}

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  @override
  void initState() {
    super.initState();
    DataService.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DataService.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final students = DataService.students;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.orange,
        foregroundColor: Colors.black,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddStudentScreen()),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
      body: students.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📭', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('Hali shogird qo\'shilmagan', style: TextStyle(color: AppTheme.muted, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: students.length,
              itemBuilder: (ctx, i) {
                final s = students[i];
                final days = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
                final scheduleText = s.schedule.map((sc) => '${days[sc.day]} ${sc.time}').join(', ');
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.orange.withOpacity(0.15),
                      child: Text(
                        s.name[0].toUpperCase(),
                        style: const TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w800),
                      ),
                    ),
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(scheduleText, style: const TextStyle(color: AppTheme.blue, fontSize: 12)),
                        if (s.pricePerLesson > 0)
                          Text('${s.pricePerLesson.toStringAsFixed(0)} so\'m/dars',
                              style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      icon: const Icon(Icons.more_vert, color: AppTheme.muted),
                      color: AppTheme.surface2,
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Tahrirlash')),
                        const PopupMenuItem(value: 'delete', child: Text('O\'chirish', style: TextStyle(color: AppTheme.red))),
                      ],
                      onSelected: (v) {
                        if (v == 'edit') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AddStudentScreen(student: s)));
                        } else if (v == 'delete') {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: AppTheme.surface,
                              title: const Text("O'chirish"),
                              content: Text("${s.name} ni o'chirish?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor')),
                                TextButton(
                                  onPressed: () {
                                    DataService.deleteStudent(s.id);
                                    Navigator.pop(context);
                                  },
                                  child: const Text("O'chirish", style: TextStyle(color: AppTheme.red)),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class AddStudentScreen extends StatefulWidget {
  final dynamic student;
  const AddStudentScreen({super.key, this.student});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _monthlyPriceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _telegramCtrl = TextEditingController();

  List<Map<String, dynamic>> _schedules = [{'day': 0, 'time': '09:00'}];
  bool _hasAlt = false;
  int _altDay = 0;
  String _altTime = '20:00';
  int _reminder = 5;
  String _paymentType = 'per_lesson';

  final _days = ['Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba', 'Juma', 'Shanba', 'Yakshanba'];

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      final s = widget.student;
      _nameCtrl.text = s.name;
      _priceCtrl.text = s.pricePerLesson > 0 ? s.pricePerLesson.toString() : '';
      _monthlyPriceCtrl.text = s.monthlyPrice != null ? s.monthlyPrice.toString() : '';
      _noteCtrl.text = s.note ?? '';
      _telegramCtrl.text = s.telegramId ?? '';
      _schedules = s.schedule.map<Map<String, dynamic>>((sc) => {'day': sc.day, 'time': sc.time}).toList();
      _reminder = s.reminderMinutes;
      _paymentType = s.paymentType;
      if (s.altSchedule != null && s.altSchedule!.enabled) {
        _hasAlt = true;
        _altDay = s.altSchedule!.day;
        _altTime = s.altSchedule!.time;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _monthlyPriceCtrl.dispose();
    _noteCtrl.dispose();
    _telegramCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(int index) async {
    final parts = _schedules[index]['time'].split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.orange),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _schedules[index]['time'] = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickAltTime() async {
    final parts = _altTime.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.orange)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _altTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    if (_schedules.isEmpty) return;

    final schedules = _schedules.map((s) => Schedule(day: s['day'], time: s['time'])).toList();
    final alt = _hasAlt ? AltSchedule(day: _altDay, time: _altTime, enabled: true) : null;

    final student = Student(
      id: widget.student?.id,
      name: _nameCtrl.text.trim(),
      schedule: schedules,
      altSchedule: alt,
      reminderMinutes: _reminder,
      pricePerLesson: int.tryParse(_priceCtrl.text) ?? 0,
      monthlyPrice: int.tryParse(_monthlyPriceCtrl.text),
      paymentType: _paymentType,
      history: widget.student?.history ?? [],
      telegramId: _telegramCtrl.text.trim().isEmpty ? null : _telegramCtrl.text.trim(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    if (widget.student == null) {
      await DataService.addStudent(student);
    } else {
      await DataService.updateStudent(student);
    }

    if (mounted) Navigator.pop(context);
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 16),
        child: Text(text.toUpperCase(),
            style: const TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      );

  Widget _inputField({required TextEditingController ctrl, required String hint, TextInputType? keyboard, int maxLines = 1}) =>
      Container(
        decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(12)),
        child: TextField(
          controller: ctrl,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: const TextStyle(color: AppTheme.textColor, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.muted),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(widget.student == null ? 'Yangi shogird' : 'Tahrirlash'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text("Saqlash", style: TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Shogird ismi'),
          _inputField(ctrl: _nameCtrl, hint: 'Ismi'),

          _sectionTitle('Dars kunlari'),
          ..._schedules.asMap().entries.map((e) {
            final i = e.key;
            final sc = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      value: sc['day'],
                      dropdownColor: AppTheme.surface2,
                      style: const TextStyle(color: AppTheme.textColor),
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _days.asMap().entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) => setState(() => _schedules[i]['day'] = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _pickTime(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
                      child: Text(sc['time'], style: const TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w700, fontSize: 18)),
                    ),
                  ),
                  if (_schedules.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppTheme.red),
                      onPressed: () => setState(() => _schedules.removeAt(i)),
                    ),
                ],
              ),
            );
          }),
          if (_schedules.length < 3)
            TextButton.icon(
              onPressed: () => setState(() => _schedules.add({'day': 0, 'time': '14:00'})),
              icon: const Icon(Icons.add, color: AppTheme.blue),
              label: const Text("Kun qo'shish", style: TextStyle(color: AppTheme.blue)),
            ),

          // Alt schedule
          _sectionTitle('Galma-gal jadval'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Toq haftalarda boshqa vaqt', style: TextStyle(fontWeight: FontWeight.w600)),
                    Switch(value: _hasAlt, onChanged: (v) => setState(() => _hasAlt = v)),
                  ],
                ),
                if (_hasAlt) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          value: _altDay,
                          dropdownColor: AppTheme.surface2,
                          style: const TextStyle(color: AppTheme.textColor),
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: _days.asMap().entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                          onChanged: (v) => setState(() => _altDay = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _pickAltTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
                          child: Text(_altTime, style: const TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w700, fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('💡 Juft haftalarda oddiy vaqt ishlatiladi', style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                ],
              ],
            ),
          ),

          // Reminder
          _sectionTitle('Eslatma vaqti'),
          Row(
            children: [5, 10, 15].map((min) {
              final selected = _reminder == min;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _reminder = min),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.orange.withOpacity(0.15) : AppTheme.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? AppTheme.orange : Colors.transparent),
                    ),
                    child: Text('$min daq', textAlign: TextAlign.center,
                        style: TextStyle(color: selected ? AppTheme.orange : AppTheme.muted, fontWeight: FontWeight.w700)),
                  ),
                ),
              );
            }).toList(),
          ),

          // Payment
          _sectionTitle('To\'lov turi'),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                _payTab('per_lesson', 'Dars uchun'),
                _payTab('monthly', 'Oylik'),
                _payTab('both', 'Ikkala'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_paymentType == 'per_lesson' || _paymentType == 'both')
            _inputField(ctrl: _priceCtrl, hint: 'Dars narxi (so\'m)', keyboard: TextInputType.number),
          if (_paymentType == 'monthly' || _paymentType == 'both') ...[
            const SizedBox(height: 8),
            _inputField(ctrl: _monthlyPriceCtrl, hint: 'Oylik narx (so\'m)', keyboard: TextInputType.number),
          ],

          _sectionTitle('Telegram ID (ixtiyoriy)'),
          _inputField(ctrl: _telegramCtrl, hint: 'Shogird Telegram ID', keyboard: TextInputType.number),

          _sectionTitle('Izoh (ixtiyoriy)'),
          _inputField(ctrl: _noteCtrl, hint: 'Shogird haqida eslatma...', maxLines: 3),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _payTab(String type, String label) {
    final selected = _paymentType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.black : AppTheme.muted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              )),
        ),
      ),
    );
  }
}
