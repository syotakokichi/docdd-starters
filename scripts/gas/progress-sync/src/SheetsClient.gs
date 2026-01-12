/**
 * SheetsClient.gs - Sheets操作ユーティリティ
 */

/**
 * 対象シートを取得
 * @returns {Sheet} シートオブジェクト
 */
function getTargetSheet() {
  const config = getConfig();
  const ss = SpreadsheetApp.getActive();
  const sheet = ss.getSheetByName(config.SHEET_NAME);

  if (!sheet) {
    throw new Error(`シート "${config.SHEET_NAME}" が見つかりません。設定を確認してください。`);
  }

  return sheet;
}

/**
 * データ範囲の行数を取得
 * @param {Sheet} sheet - シートオブジェクト
 * @returns {number} 最終行番号
 */
function getLastDataRow(sheet) {
  const config = getConfig();
  const lastRow = sheet.getLastRow();
  return Math.max(lastRow, config.DATA_START_ROW);
}

/**
 * Issue番号で行を検索
 * @param {Sheet} sheet - シートオブジェクト
 * @param {number} issueNumber - Issue番号
 * @returns {number|null} 行番号（見つからない場合はnull）
 */
function findRowByIssueNumber(sheet, issueNumber) {
  const config = getConfig();
  const col = getColumnIndex(sheet, HEADER_NAMES.ISSUE_NUMBER);
  if (col < 0) return null;

  const lastRow = getLastDataRow(sheet);
  const range = sheet.getRange(config.DATA_START_ROW, col, lastRow - config.DATA_START_ROW + 1, 1);
  const values = range.getValues();

  for (let i = 0; i < values.length; i++) {
    if (values[i][0] == issueNumber) {
      return config.DATA_START_ROW + i;
    }
  }

  return null;
}

/**
 * 同期対象の行を全て取得
 * @param {Sheet} sheet - シートオブジェクト
 * @returns {Array<{row: number, data: Object}>} 行データ配列
 */
function getSyncableRows(sheet) {
  const config = getConfig();
  const lastRow = getLastDataRow(sheet);
  const rows = [];

  for (let row = config.DATA_START_ROW; row <= lastRow; row++) {
    const data = getRowData(sheet, row);

    // タスク名がない行はスキップ
    if (!data[HEADER_NAMES.TASK]) continue;

    // 同期対象外ステータスはスキップ
    if (isSkipStatus(data[HEADER_NAMES.STATUS])) continue;

    rows.push({ row, data });
  }

  return rows;
}

/**
 * 未同期の行を取得
 * @param {Sheet} sheet - シートオブジェクト
 * @returns {Array<{row: number, data: Object}>} 未同期の行データ配列
 */
function getUnsyncedRows(sheet) {
  const rows = getSyncableRows(sheet);

  return rows.filter(({ data }) => {
    const issueNumber = data[HEADER_NAMES.ISSUE_NUMBER];
    const syncStatus = data[HEADER_NAMES.SYNC_STATUS];

    // Issue番号がない、または同期ステータスが未同期/エラー
    return !issueNumber ||
      syncStatus === SYNC_STATUS.NOT_SYNCED ||
      syncStatus === SYNC_STATUS.ERROR ||
      !syncStatus;
  });
}

/**
 * 行に Issue 番号と同期ステータスを書き込む
 * @param {Sheet} sheet - シートオブジェクト
 * @param {number} row - 行番号
 * @param {number} issueNumber - Issue番号
 * @param {string} syncStatus - 同期ステータス
 */
function writeIssueInfo(sheet, row, issueNumber, syncStatus) {
  setCellValue(sheet, row, HEADER_NAMES.ISSUE_NUMBER, issueNumber);
  setCellValue(sheet, row, HEADER_NAMES.SYNC_STATUS, syncStatus);
}

/**
 * 行のステータスを更新
 * @param {Sheet} sheet - シートオブジェクト
 * @param {number} row - 行番号
 * @param {string} status - 新しいステータス
 */
function updateRowStatus(sheet, row, status) {
  setCellValue(sheet, row, HEADER_NAMES.STATUS, status);
}

/**
 * ヘッダ行に必要な列を追加
 * @param {Sheet} sheet - シートオブジェクト
 */
function ensureRequiredColumns(sheet) {
  const config = getConfig();
  let lastCol = sheet.getLastColumn();

  // シートが空または列がない場合
  let headers = [];
  if (lastCol > 0) {
    headers = sheet.getRange(config.HEADER_ROW, 1, 1, lastCol).getValues()[0];
  }

  const requiredColumns = [
    HEADER_NAMES.ISSUE_NUMBER,
    HEADER_NAMES.PR_NUMBER,
    HEADER_NAMES.SYNC_STATUS
  ];

  requiredColumns.forEach(colName => {
    if (!headers.includes(colName)) {
      lastCol++;
      sheet.getRange(config.HEADER_ROW, lastCol).setValue(colName);
      log(`Added column: ${colName} at column ${lastCol}`);
    }
  });
}
