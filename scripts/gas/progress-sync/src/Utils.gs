/**
 * Utils.gs - 共通ユーティリティ関数
 */

const SYNC_LOCK_PREFIX = 'sync_lock_row_';
const SYNC_LOCK_DURATION = 30;

/**
 * 行単位の同期ロックを設定
 * @param {number} row - 行番号
 */
function setSyncLock(row) {
  CacheService.getScriptCache()
    .put(SYNC_LOCK_PREFIX + row, 'true', SYNC_LOCK_DURATION);
}

/**
 * 行単位の同期ロックがあるか確認
 * @param {number} row - 行番号
 * @returns {boolean} ロックがある場合はtrue
 */
function hasSyncLock(row) {
  return CacheService.getScriptCache()
    .get(SYNC_LOCK_PREFIX + row) !== null;
}

/**
 * ヘッダ行から列インデックスを取得（1-based）
 * @param {Sheet} sheet - Sheetsオブジェクト
 * @param {string} headerName - ヘッダ名
 * @returns {number} 列番号（1-based）、見つからない場合は -1
 */
function getColumnIndex(sheet, headerName) {
  const config = getConfig();
  const headers = sheet.getRange(config.HEADER_ROW, 1, 1, sheet.getLastColumn()).getValues()[0];
  const index = headers.indexOf(headerName);
  return index >= 0 ? index + 1 : -1;
}

/**
 * 行データをオブジェクトに変換
 * @param {Sheet} sheet - Sheetsオブジェクト
 * @param {number} row - 行番号（1-based）
 * @returns {Object} 行データオブジェクト
 */
function getRowData(sheet, row) {
  const config = getConfig();
  const headers = sheet.getRange(config.HEADER_ROW, 1, 1, sheet.getLastColumn()).getValues()[0];
  const values = sheet.getRange(row, 1, 1, sheet.getLastColumn()).getValues()[0];

  const data = {};
  headers.forEach((header, index) => {
    if (header) {
      data[header] = values[index];
    }
  });

  return data;
}

/**
 * 列値を更新
 * @param {Sheet} sheet - Sheetsオブジェクト
 * @param {number} row - 行番号（1-based）
 * @param {string} headerName - ヘッダ名
 * @param {any} value - 設定する値
 */
function setCellValue(sheet, row, headerName, value) {
  const col = getColumnIndex(sheet, headerName);
  if (col > 0) {
    sheet.getRange(row, col).setValue(value);
  }
}

/**
 * 列値を取得
 * @param {Sheet} sheet - Sheetsオブジェクト
 * @param {number} row - 行番号（1-based）
 * @param {string} headerName - ヘッダ名
 * @returns {any} セルの値
 */
function getCellValue(sheet, row, headerName) {
  const col = getColumnIndex(sheet, headerName);
  if (col > 0) {
    return sheet.getRange(row, col).getValue();
  }
  return null;
}

/**
 * ログ出力（デバッグ用）
 * @param {string} message - メッセージ
 * @param {any} data - 追加データ（オプション）
 */
function log(message, data = null) {
  const timestamp = new Date().toISOString();
  if (data) {
    Logger.log(`[${timestamp}] ${message}: ${JSON.stringify(data)}`);
  } else {
    Logger.log(`[${timestamp}] ${message}`);
  }
}

/**
 * エラーログ出力
 * @param {string} message - メッセージ
 * @param {Error} error - エラーオブジェクト
 */
function logError(message, error) {
  const timestamp = new Date().toISOString();
  Logger.log(`[${timestamp}] ERROR: ${message}`);
  Logger.log(`  Message: ${error.message}`);
  Logger.log(`  Stack: ${error.stack}`);
}

/**
 * 日付を YYYY-MM-DD 形式にフォーマット
 * @param {Date|string} date - 日付
 * @returns {string} フォーマット済み日付
 */
function formatDate(date) {
  if (!date) return '';
  const d = new Date(date);
  if (isNaN(d.getTime())) return '';
  return Utilities.formatDate(d, Session.getScriptTimeZone(), 'yyyy-MM-dd');
}

/**
 * 文字列をスラッグ化（Issue タイトル → ブランチ名用）
 * @param {string} str - 元の文字列
 * @param {number} maxLength - 最大長
 * @returns {string} スラッグ化された文字列
 */
function slugify(str, maxLength = 50) {
  return str
    .toLowerCase()
    .replace(/[^a-z0-9\u3040-\u309f\u30a0-\u30ff\u4e00-\u9faf]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .substring(0, maxLength);
}
