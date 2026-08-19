import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/repair_order.dart';
import '../models/debt.dart';

/// خدمة إرسال البيانات إلى Google Sheets عبر Google Apps Script (Web App)
///
/// طريقة العمل:
/// 1. تُنشئ Google Apps Script منشور كـ Web App (انظر ملف google_apps_script.gs
///    وشرح خطوات الإعداد في README.md).
/// 2. يعطيك جوجل رابطاً (URL) ينتهي بـ /exec — ضعه في المتغير `scriptUrl` أدناه.
/// 3. كل عملية حفظ أو تحديث في التطبيق تُرسِل طلب POST بصيغة JSON إلى هذا الرابط،
///    والسكريبت في جوجل يقوم بإضافة السطر المناسب في الشيت الصحيح.
class SheetsService {
  // ⚠️ استبدل هذا الرابط برابط الـ Web App الخاص بك بعد نشر السكريبت
  static const String scriptUrl =
      'https://script.google.com/macros/s/PASTE_YOUR_DEPLOYMENT_ID_HERE/exec';

  static bool get isConfigured =>
      !scriptUrl.contains('PASTE_YOUR_DEPLOYMENT_ID_HERE');

  /// إرسال بيانات عملية صيانة جديدة إلى شيت "العمليات"
  static Future<bool> sendOrder(RepairOrder order) async {
    return _post({
      'sheet': 'orders',
      'action': 'upsert',
      'data': {
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
      },
    });
  }

  /// إرسال بيانات دين (مورد أو زبون) إلى شيت "الديون"
  static Future<bool> sendDebt(Debt debt) async {
    return _post({
      'sheet': 'debts',
      'action': 'upsert',
      'data': {
        'id': debt.id,
        'التاريخ': debt.createdAt.toIso8601String(),
        'النوع': debt.type == DebtType.supplier ? 'مورد' : 'زبون',
        'الاسم': debt.personName,
        'المبلغ': debt.amount,
        'ملاحظة': debt.note,
        'مدفوع': debt.paid ? 'نعم' : 'لا',
      },
    });
  }

  /// إرسال تقرير الغلق الأسبوعي إلى شيت "التقارير الأسبوعية"
  static Future<bool> sendWeeklyReport(Map<String, dynamic> reportData) async {
    return _post({
      'sheet': 'weekly_reports',
      'action': 'append',
      'data': reportData,
    });
  }

  static Future<bool> _post(Map<String, dynamic> body) async {
    if (!isConfigured) {
      // لم يتم إعداد رابط السكريبت بعد — نتجاهل الإرسال دون التسبب بخطأ
      return false;
    }
    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      // في حال انعدام الاتصال بالإنترنت، تبقى البيانات محفوظة محلياً
      // ويمكن إعادة المزامنة لاحقاً
      return false;
    }
  }
}
