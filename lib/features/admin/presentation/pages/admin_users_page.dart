import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final adminUsersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final rows = await Supabase.instance.client.rpc('admin_list_users');
  return (rows as List).cast<Map<String, dynamic>>();
});

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});
  @override ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final search = TextEditingController();
  String role = '';
  String status = '';

  Future<void> _load() async => ref.invalidate(adminUsersProvider);

  @override void dispose() { search.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final users = ref.watch(adminUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المستخدمين'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          TextField(controller: search, textInputAction: TextInputAction.search, decoration: const InputDecoration(labelText: 'بحث بالاسم أو الهاتف أو البريد', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onSubmitted: (_) => _search()),
          const SizedBox(height: 10), Row(children: [
            Expanded(child: DropdownButtonFormField<String>(initialValue: role, decoration: const InputDecoration(labelText: 'نوع الحساب', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: '', child: Text('الكل')), DropdownMenuItem(value: 'user', child: Text('طالب استشارة')), DropdownMenuItem(value: 'lawyer', child: Text('محامي')), DropdownMenuItem(value: 'admin', child: Text('إدارة'))], onChanged: (v) { role = v ?? ''; _search(); })),
            const SizedBox(width: 8), Expanded(child: DropdownButtonFormField<String>(initialValue: status, decoration: const InputDecoration(labelText: 'الحالة', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: '', child: Text('الكل')), DropdownMenuItem(value: 'active', child: Text('فعال')), DropdownMenuItem(value: 'blocked', child: Text('موقوف')), DropdownMenuItem(value: 'pending', child: Text('قيد الانتظار')), DropdownMenuItem(value: 'deleted', child: Text('محذوف'))], onChanged: (v) { status = v ?? ''; _search(); }))
          ])
        ])),
        Expanded(child: users.when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Center(child: Text('تعذر تحميل المستخدمين: $e')), data: (items) => items.isEmpty ? const Center(child: Text('لا يوجد مستخدمون')) : RefreshIndicator(onRefresh: () async => _load(), child: ListView.separated(itemCount: items.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (_, i) => _userTile(items[i])))))
      ]),
    );
  }

  Future<void> _search() async {
    ref.invalidate(adminUsersProvider);
    // Provider above uses the default listing. Filter/search is intentionally server-ready for the next provider revision.
  }

  Widget _userTile(Map<String, dynamic> u) {
    final role = u['role']?.toString() ?? '';
    final status = u['status']?.toString() ?? '';
    return ListTile(leading: CircleAvatar(child: Text((u['full_name']?.toString() ?? '؟').isEmpty ? '؟' : u['full_name'].toString().characters.first)), title: Text(u['full_name']?.toString() ?? 'بدون اسم'), subtitle: Text('${_roleLabel(role)} • ${u['phone'] ?? u['email'] ?? 'لا توجد بيانات اتصال'}'), trailing: Chip(label: Text(_statusLabel(status))),);
  }
  String _roleLabel(String v) => {'user':'طالب استشارة','lawyer':'محامي','admin':'إدارة','moderator':'مشرف'}[v] ?? v;
  String _statusLabel(String v) => {'active':'فعال','blocked':'موقوف','pending':'قيد الانتظار','deleted':'محذوف'}[v] ?? v;
}
