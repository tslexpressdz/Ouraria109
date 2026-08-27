import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/repair_order.dart';
import '../models/debt.dart';

class SheetsService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [sheets.SheetsApi.spreadsheetsScope],
  );

  static GoogleSignInAccount? _account;
  static sheets.SheetsApi? _api;
  static String? _spreadsheetId;
  static final Set<String> _ensuredTabs = {};

  static bool get isSignedIn => _account != null;
  static bool get isConfigured => _api != null && _spreadsheetId != null;
  static String? get userEmail => _account?.email;
  static String? get spreadsheetId => _spreadsheetId;

  static const Map<String, String> _sheetTitles = {
    'orders': 'العمليات',
    'debts': 'الديون',
    'weekly_reports': 'التقارير الأسبوعية',
  };

  static Future<bool> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return false;
      await _afterSignIn(account);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String? lastError;

  static Future<bool> signIn() async {
    lastError = null;
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        lastError = 'المستخدم ألغى تسجيل الدخول (account == null)';
        return false;
      }
      await _afterSignIn(account);
      return true;
    } catch (e) {
      lastError = e.toString();
      return false;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    _account = null;
    _api = null;
    _spreadsheetId = null;
    _ensuredTabs.clear();
  }

  static Future<void> _afterSignIn(GoogleSignInAccount account) async {
    _account = account;
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) throw Exception('تعذر إنشاء اتصال مصادق');
    _api = sheets.SheetsApi(client);

    final prefs = await SharedPreferences.getInstance();
    final key = 'spreadsheet_id_${account.id}';
    String? savedId = prefs.getString(key);

    if (savedId != null) {
      try {
        await _api!.spreadsheets.get(savedId);
        _spreadsheetId = savedId;
        return;
      } catch (_) {
        savedId = null;
      }
    }

    final spreadsheet = sheets.Spreadsheet(
      properties: sheets.SpreadsheetProperties(title: 'سجل محل الصيانة'),
    );
    final created = await _api!.spreadsheets.create(spreadsheet);
    _spreadsheetId = created.spreadsheetId;
    await prefs.setString(key, _spreadsheetId!);
  }

  static Future<bool> sendOrder(RepairOrder order) {
    return _upsert('orders', {
      'id': order.id,
      'التاريخ': order.createdAt.toIso8601String(),
      'اسم الزبون': order.customerName,
      'رقم الهاتف': order.customerPhone,
      'نوع الهاتف': order.deviceType,
      'القطعة': order.partName,
      'سعر الشراء': order.purchasePrice,
      'سعر البيع': order.sellPrice,
      'العربون': order.deposit,
      'المتبقي': order.remainingAmount,
      'الفائدة الإجمالية': order.totalProfit,
      'فائدتي': order.myProfitShare,
      'فائدة الشريك': order.ownerProfitShare,
      'الحالة': order.status.label,
    });
  }

  static Future<bool> sendDebt(Debt debt) {
    return _upsert('debts', {
      'id': debt.id,
      'التاريخ': debt.createdAt.toIso8601String(),
      'النوع': debt.type == DebtType.supplier ? 'مورد' : 'زبون',
      'الاسم': debt.personName,
      'المبلغ': debt.amount,
      'ملاحظة': debt.note,
      'مدفوع': debt.paid ? 'نعم' : 'لا',
    });
  }

  static Future<bool> sendWeeklyReport(Map<String, dynamic> reportData) {
    return _append('weekly_reports', reportData);
  }

  static Future<bool> _upsert(String key, Map<String, dynamic> data) async {
    if (!isConfigured) return false;
    try {
      final tab = _sheetTitles[key]!;
      final headers = data.keys.toList();
      await _ensureTab(tab, headers);

      final idResp = await _api!.spreadsheets.values.get(
        _spreadsheetId!,
        "'$tab'!A2:A",
      );
      final ids = idResp.values ?? [];
      int? rowNumber;
      for (var i = 0; i < ids.length; i++) {
        if (ids[i].isNotEmpty && ids[i][0].toString() == data['id'].toString()) {
          rowNumber = i + 2;
          break;
        }
      }

      final row = headers.map((h) => data[h]?.toString() ?? '').toList();
      if (rowNumber != null) {
        await _api!.spreadsheets.values.update(
          sheets.ValueRange(values: [row]),
          _spreadsheetId!,
          "'$tab'!A$rowNumber",
          valueInputOption: 'USER_ENTERED',
        );
      } else {
        await _api!.spreadsheets.values.append(
          sheets.ValueRange(values: [row]),
          _spreadsheetId!,
          "'$tab'!A1",
          valueInputOption: 'USER_ENTERED',
          insertDataOption: 'INSERT_ROWS',
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _append(String key, Map<String, dynamic> data) async {
    if (!isConfigured) return false;
    try {
      final tab = _sheetTitles[key]!;
      final headers = data.keys.toList();
      await _ensureTab(tab, headers);
      final row = headers.map((h) => data[h]?.toString() ?? '').toList();
      await _api!.spreadsheets.values.append(
        sheets.ValueRange(values: [row]),
        _spreadsheetId!,
        "'$tab'!A1",
        valueInputOption: 'USER_ENTERED',
        insertDataOption: 'INSERT_ROWS',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _ensureTab(String tabTitle, List<String> headers) async {
    if (_ensuredTabs.contains(tabTitle)) return;
    final spreadsheet = await _api!.spreadsheets.get(_spreadsheetId!);
    final exists =
        spreadsheet.sheets?.any((s) => s.properties?.title == tabTitle) ??
            false;

    if (!exists) {
      await _api!.spreadsheets.batchUpdate(
        sheets.BatchUpdateSpreadsheetRequest(requests: [
          sheets.Request(
            addSheet: sheets.AddSheetRequest(
              properties: sheets.SheetProperties(title: tabTitle),
            ),
          ),
        ]),
        _spreadsheetId!,
      );
      await _api!.spreadsheets.values.update(
        sheets.ValueRange(values: [headers]),
        _spreadsheetId!,
        "'$tabTitle'!A1",
        valueInputOption: 'USER_ENTERED',
      );
    }
    _ensuredTabs.add(tabTitle);
  }
}
