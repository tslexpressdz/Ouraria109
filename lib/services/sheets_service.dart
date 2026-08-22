/**
 * google_apps_script.gs
 * -----------------------------------------------------------------------
 * هذا السكريبت يُنشر كـ "Web App" داخل Google Sheets، ويستقبل طلبات POST
 * من تطبيق Flutter (عبر SheetsService) ويقوم بإضافة/تحديث البيانات
 * في الشيتات المناسبة.
 *
 * خطوات الإعداد موجودة بالتفصيل في README.md
 * -----------------------------------------------------------------------
 */

// أسماء الشيتات المستخدمة داخل ملف Google Sheets
const SHEET_NAMES = {
  orders: 'العمليات',
  debts: 'الديون',
  weekly_reports: 'التقارير الأسبوعية',
};

/**
 * نقطة الدخول الرئيسية: تستقبل كل طلبات POST القادمة من التطبيق
 */
function doPost(e) {
  try {
    const body = JSON.parse(e.postData.contents);
    const sheetKey = body.sheet; // orders | debts | weekly_reports
    const action = body.action; // upsert | append
    const data = body.data;

    const sheetName = SHEET_NAMES[sheetKey];
    if (!sheetName) {
      return _jsonResponse({ok: false, error: 'اسم شيت غير معروف: ' + sheetKey});
    }

    const sheet = _getOrCreateSheet(sheetName, data);

    if (action === 'upsert' && data.id) {
      _upsertRow(sheet, data);
    } else {
      _appendRow(sheet, data);
    }

    return _jsonResponse({ok: true});
  } catch (err) {
    return _jsonResponse({ok: false, error: err.toString()});
  }
}

/**
 * يسمح بفتح الرابط من المتصفح للتأكد من أن الخدمة تعمل
 */
function doGet(e) {
  return ContentService.createTextOutput(
    'خدمة ربط تطبيق إدارة محل الصيانة تعمل بنجاح ✅'
  );
}

/**
 * يبحث عن الشيت المطلوب، وإن لم يكن موجوداً ينشئه مع صف العناوين
 */
function _getOrCreateSheet(sheetName, sampleData) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(sheetName);
  if (!sheet) {
    sheet = ss.insertSheet(sheetName);
    const headers = Object.keys(sampleData);
    sheet.appendRow(headers);
    sheet.getRange(1, 1, 1, headers.length).setFontWeight('bold');
    sheet.setFrozenRows(1);
  }
  return sheet;
}

/**
 * إضافة صف جديد دائماً (تُستخدم للتقارير الأسبوعية)
 */
function _appendRow(sheet, data) {
  const headers = _getHeaders(sheet, data);
  const row = headers.map((h) => (data[h] !== undefined ? data[h] : ''));
  sheet.appendRow(row);
}

/**
 * تحديث الصف إن وُجد نفس id مسبقاً، وإلا إضافة صف جديد (تُستخدم للعمليات والديون)
 */
function _upsertRow(sheet, data) {
  const headers = _getHeaders(sheet, data);
  const idColIndex = headers.indexOf('id') + 1;
  const lastRow = sheet.getLastRow();

  if (lastRow >= 2 && idColIndex > 0) {
    const ids = sheet.getRange(2, idColIndex, lastRow - 1, 1).getValues();
    for (let i = 0; i < ids.length; i++) {
      if (ids[i][0] === data.id) {
        const row = headers.map((h) => (data[h] !== undefined ? data[h] : ''));
        sheet.getRange(i + 2, 1, 1, row.length).setValues([row]);
        return;
      }
    }
  }
  _appendRow(sheet, data);
}

function _getHeaders(sheet, data) {
  const lastCol = sheet.getLastColumn();
  if (lastCol === 0) {
    const headers = Object.keys(data);
    sheet.appendRow(headers);
    sheet.getRange(1, 1, 1, headers.length).setFontWeight('bold');
    sheet.setFrozenRows(1);
    return headers;
  }
  return sheet.getRange(1, 1, 1, lastCol).getValues()[0];
}

function _jsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(
    ContentService.MimeType.JSON
  );
}
