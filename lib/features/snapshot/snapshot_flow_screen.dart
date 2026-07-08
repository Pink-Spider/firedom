import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money_format.dart';
import '../../core/ym.dart';
import '../../data/db/database.dart';
import '../../data/db/providers.dart';
import '../../data/prefs.dart';
import 'snapshot_result_screen.dart';

const _assetClassLabels = {
  'cash': '현금/예금',
  'equity': '주식',
  'bond': '채권',
  'real_estate': '부동산',
  'pension': '연금',
  'other': '기타',
};

/// S5→S8. 월 스냅샷 기록 플로우 (PRD) ★ retention 심장
///
/// 전월 값 복사 기본 → 항목별 금액 수정 → 소득/지출 2필드 → 원자적 저장 →
/// 결과 리빌. 과거 월 소급 입력 가능, 중간 이탈 시 draft 보존.
class SnapshotFlowScreen extends ConsumerStatefulWidget {
  static const path = '/snapshot';

  const SnapshotFlowScreen({super.key});

  @override
  ConsumerState<SnapshotFlowScreen> createState() =>
      _SnapshotFlowScreenState();
}

class _SnapshotFlowScreenState extends ConsumerState<SnapshotFlowScreen> {
  int _ym = nowYm();
  bool _loading = true;
  bool _saving = false;
  List<Account> _accounts = const [];
  final Map<String, TextEditingController> _amountControllers = {};
  final _incomeController = TextEditingController();
  final _expenseController = TextEditingController();

  /// 초기값 세팅 중 draft가 덮어써지는 것을 막는다
  bool _suppressDraftWrites = true;

  String get _draftKey => 'snapshot.draft.$_ym';

  @override
  void initState() {
    super.initState();
    _incomeController.addListener(_writeDraft);
    _expenseController.addListener(_writeDraft);
    _load();
  }

  @override
  void dispose() {
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    _incomeController.dispose();
    _expenseController.dispose();
    super.dispose();
  }

  Account? _accountById(String id) {
    for (final account in _accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  int _signedAmount(Account account, String text) {
    final raw = parseAmount(text) ?? 0;
    return account.isLiability ? -raw : raw;
  }

  // ── 초기값: draft > 기존 스냅샷(소급 수정) > 전월 복사 ──────────

  Future<void> _load() async {
    setState(() => _loading = true);
    _suppressDraftWrites = true;

    final repository = ref.read(snapshotRepositoryProvider);
    final accounts = await repository.ensureDefaultAccounts();

    var amounts = <String, int>{};
    int? income;
    int? expense;

    final draft = _readDraft();
    if (draft != null) {
      amounts = draft.amounts;
      income = draft.income;
      expense = draft.expense;
    } else {
      final existing = await repository.getByYm(_ym);
      if (existing != null) {
        final items = await repository.itemsOf(existing.id);
        amounts = {for (final item in items) item.accountId: item.amount};
        income = existing.income;
        expense = existing.expense;
      } else {
        // 전월 값 복사 후 수정 (PRD S8)
        amounts = await repository.latestAmountsBefore(_ym);
      }
    }

    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    _amountControllers.clear();
    for (final account in accounts) {
      final amount = amounts[account.id] ?? 0;
      final controller = TextEditingController(
        text: amount == 0 ? '' : formatWithComma(amount.abs()),
      );
      controller.addListener(_writeDraft);
      _amountControllers[account.id] = controller;
    }
    _incomeController.text = income == null ? '' : formatWithComma(income);
    _expenseController.text = expense == null ? '' : formatWithComma(expense);

    _suppressDraftWrites = false;
    setState(() {
      _accounts = accounts;
      _loading = false;
    });
  }

  // ── draft 보존 (중간 이탈 대비, PRD S8 수용 기준) ────────────────

  ({Map<String, int> amounts, int? income, int? expense})? _readDraft() {
    final raw = ref.read(sharedPreferencesProvider).getString(_draftKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return (
      amounts: (map['amounts'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as int)),
      income: map['income'] as int?,
      expense: map['expense'] as int?,
    );
  }

  void _writeDraft() {
    if (_suppressDraftWrites) return;
    ref.read(sharedPreferencesProvider).setString(
          _draftKey,
          jsonEncode({
            'amounts': {
              for (final entry in _amountControllers.entries)
                if (_accountById(entry.key) != null)
                  entry.key: _signedAmount(
                      _accountById(entry.key)!, entry.value.text),
            },
            'income': parseAmount(_incomeController.text),
            'expense': parseAmount(_expenseController.text),
          }),
        );
  }

  // ── 저장 (원자적 — 리포지토리 트랜잭션) ─────────────────────────

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final repository = ref.read(snapshotRepositoryProvider);
    final amounts = {
      for (final account in _accounts)
        account.id:
            _signedAmount(account, _amountControllers[account.id]!.text),
    };
    await repository.saveSnapshot(
      ym: _ym,
      amountsByAccountId: amounts,
      income: parseAmount(_incomeController.text),
      expense: parseAmount(_expenseController.text),
    );
    await ref.read(sharedPreferencesProvider).remove(_draftKey);
    if (mounted) {
      context.pushReplacement('${SnapshotResultScreen.path}?ym=$_ym');
    }
  }

  // ── 항목 관리 ───────────────────────────────────────────────

  Future<void> _addAccount() async {
    final nameController = TextEditingController();
    var assetClass = 'cash';
    var isLiability = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('항목 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: '항목 이름'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: assetClass,
                decoration: const InputDecoration(labelText: '자산군'),
                items: [
                  for (final entry in _assetClassLabels.entries)
                    DropdownMenuItem(
                        value: entry.key, child: Text(entry.value)),
                ],
                onChanged: (value) =>
                    setDialogState(() => assetClass = value ?? 'cash'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('부채 (음수로 계산)'),
                value: isLiability,
                onChanged: (value) =>
                    setDialogState(() => isLiability = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );

    final name = nameController.text.trim();
    if (confirmed != true || name.isEmpty) return;

    final account = await ref.read(snapshotRepositoryProvider).createAccount(
          name: name,
          assetClass: assetClass,
          isLiability: isLiability,
        );
    final controller = TextEditingController();
    controller.addListener(_writeDraft);
    setState(() {
      _accounts = [..._accounts, account];
      _amountControllers[account.id] = controller;
    });
  }

  Future<void> _renameAccount(Account account) async {
    final controller = TextEditingController(text: account.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이름 변경'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('변경'),
          ),
        ],
      ),
    );
    final name = controller.text.trim();
    if (confirmed != true || name.isEmpty) return;

    await ref.read(snapshotRepositoryProvider).renameAccount(account.id, name);
    setState(() {
      _accounts = [
        for (final a in _accounts)
          a.id == account.id ? a.copyWith(name: name) : a,
      ];
    });
  }

  Future<void> _deleteAccount(Account account) async {
    await ref
        .read(snapshotRepositoryProvider)
        .softDeleteAccount(account.id);
    _amountControllers.remove(account.id)?.dispose();
    setState(() {
      _accounts = [..._accounts]..removeWhere((a) => a.id == account.id);
    });
    _writeDraft();
  }

  void _changeMonth(int delta) {
    setState(() => _ym = ymAddMonths(_ym, delta));
    _load();
  }

  // ── UI ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('자산 기록')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  // 과거 월 소급 입력 (PRD S8)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(formatYm(_ym),
                              style: theme.textTheme.titleMedium),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed:
                            _ym < nowYm() ? () => _changeMonth(1) : null,
                      ),
                    ],
                  ),
                  Text('자산 항목', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '지난달 값이 채워져 있어요 — 바뀐 항목만 고치면 돼요',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final account in _accounts) _accountRow(account),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addAccount,
                      icon: const Icon(Icons.add),
                      label: const Text('항목 추가'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('이번 달 소득 · 지출 (선택)',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '적으면 저축률 추이를 볼 수 있어요',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const ValueKey('income-field'),
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: '세후 소득',
                      suffixText: '원',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('expense-field'),
                    controller: _expenseController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: '지출',
                      suffixText: '원',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('저장'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _accountRow(Account account) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              key: ValueKey('amount-${account.name}'),
              controller: _amountControllers[account.id],
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              decoration: InputDecoration(
                labelText: account.name,
                prefixText: account.isLiability ? '−' : null,
                suffixText: '원',
                helperText: account.isLiability
                    ? '${_assetClassLabels[account.assetClass] ?? '기타'} · 부채'
                    : _assetClassLabels[account.assetClass],
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: theme.colorScheme.onSurfaceVariant),
            onSelected: (action) {
              if (action == 'rename') _renameAccount(account);
              if (action == 'delete') _deleteAccount(account);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'rename', child: Text('이름 변경')),
              PopupMenuItem(value: 'delete', child: Text('삭제')),
            ],
          ),
        ],
      ),
    );
  }
}
