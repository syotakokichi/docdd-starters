/**
 * SheetsToGitHub.gs - Sheets → GitHub Issue 同期
 *
 * onEdit トリガーで行の追加・変更を検知し、GitHub Issue を作成・更新
 */

/**
 * 行データから GitHub Issue を作成
 * @param {Sheet} sheet - シートオブジェクト
 * @param {number} row - 行番号
 * @param {Object} rowData - 行データオブジェクト
 * @returns {number} 作成された Issue 番号
 */
function createIssueFromRow(sheet, row, rowData) {
  const taskName = rowData[HEADER_NAMES.TASK];
  if (!taskName) {
    throw new Error('タスク名が空です');
  }

  // Labels 生成
  const labels = generateLabelsFromRow(rowData);
  const statusMapping = mapStatusToGitHub(rowData[HEADER_NAMES.STATUS]);
  if (statusMapping.label) {
    labels.push(statusMapping.label);
  }

  // Issue 作成
  const issueData = {
    title: taskName,
    body: generateIssueBody(rowData),
    labels: labels,
    assignees: parseAssignees(rowData[HEADER_NAMES.ASSIGNEE])
  };

  const issue = createIssue(issueData);

  // ステータスが「完了」の場合はクローズ
  if (statusMapping.state === 'closed') {
    closeIssue(issue.number);
  }

  // Sheets に Issue 番号と同期ステータスを書き戻し
  writeIssueInfo(sheet, row, issue.number, SYNC_STATUS.SYNCED);

  log('Issue created from row', { row, issueNumber: issue.number });
  return issue.number;
}

/**
 * 既存 Issue を行データで更新
 * @param {Sheet} sheet - シートオブジェクト
 * @param {number} row - 行番号
 * @param {Object} rowData - 行データオブジェクト
 * @param {number} issueNumber - 既存 Issue 番号
 */
function updateIssueFromRow(sheet, row, rowData, issueNumber) {
  const taskName = rowData[HEADER_NAMES.TASK];

  // Labels 生成
  const labels = generateLabelsFromRow(rowData);
  const statusMapping = mapStatusToGitHub(rowData[HEADER_NAMES.STATUS]);
  if (statusMapping.label) {
    labels.push(statusMapping.label);
  }

  // Issue 更新
  const updateData = {
    title: taskName,
    body: generateIssueBody(rowData),
    state: statusMapping.state
  };

  updateIssue(issueNumber, updateData);
  setIssueLabels(issueNumber, labels);

  // 同期ステータスを更新
  setCellValue(sheet, row, HEADER_NAMES.SYNC_STATUS, SYNC_STATUS.SYNCED);

  log('Issue updated from row', { row, issueNumber });
}

/**
 * 1行を GitHub に同期
 * @param {number} row - 行番号
 */
function syncRowToGitHub(row) {
  const sheet = getTargetSheet();
  const config = getConfig();

  // ヘッダ行より上は無視
  if (row < config.DATA_START_ROW) return;

  const rowData = getRowData(sheet, row);

  // タスク名がない行はスキップ
  if (!rowData[HEADER_NAMES.TASK]) {
    log('Skipping row without task name', { row });
    return;
  }

  // 同期対象外ステータスはスキップ
  if (isSkipStatus(rowData[HEADER_NAMES.STATUS])) {
    log('Skipping row with skip status', { row, status: rowData[HEADER_NAMES.STATUS] });
    return;
  }

  // 同期中フラグを設定（ループ防止）
  setCellValue(sheet, row, HEADER_NAMES.SYNC_STATUS, SYNC_STATUS.SYNCING);

  try {
    const existingIssueNumber = rowData[HEADER_NAMES.ISSUE_NUMBER];

    if (existingIssueNumber) {
      // 既存 Issue を更新
      updateIssueFromRow(sheet, row, rowData, existingIssueNumber);
    } else {
      // 新規 Issue を作成
      createIssueFromRow(sheet, row, rowData);
    }
  } catch (e) {
    logError('Failed to sync row', e);
    setCellValue(sheet, row, HEADER_NAMES.SYNC_STATUS, SYNC_STATUS.ERROR);
    throw e;
  }
}

/**
 * onEdit トリガーハンドラ（インストール型トリガー用）
 * 複数行編集（貼り付け等）にも対応
 * @param {Object} e - イベントオブジェクト
 */
function onEditTrigger(e) {
  // ロックを取得（同時実行防止）
  const lock = LockService.getScriptLock();
  if (!lock.tryLock(10000)) {
    log('Could not acquire lock, skipping');
    return;
  }

  try {
    if (!e || !e.range) {
      log('No event range, skipping');
      return;
    }

    const sheet = e.range.getSheet();
    const config = getConfig();

    // 対象シート以外は無視
    if (sheet.getName() !== config.SHEET_NAME) return;

    // 編集範囲の情報を取得
    const startRow = e.range.getRow();
    const numRows = e.range.getNumRows();
    const startCol = e.range.getColumn();
    const numCols = e.range.getNumColumns();

    // 同期ステータス列への書き込みは無視（ループ防止）
    const syncStatusCol = getColumnIndex(sheet, HEADER_NAMES.SYNC_STATUS);

    // Issue番号列への書き込みは無視（ループ防止）
    const issueNumberCol = getColumnIndex(sheet, HEADER_NAMES.ISSUE_NUMBER);

    // PR番号列への書き込みは無視（ループ防止）
    const prNumberCol = getColumnIndex(sheet, HEADER_NAMES.PR_NUMBER);
    const ignoredCols = [syncStatusCol, issueNumberCol, prNumberCol].filter(col => col > 0);

    if (ignoredCols.length > 0 && isEditInIgnoredColumns(startCol, numCols, ignoredCols)) {
      log('Ignoring edit in sync/issue/pr columns');
      return;
    }

    // 編集された全行を処理
    for (let i = 0; i < numRows; i++) {
      const row = startRow + i;

      // ヘッダ行より上は無視
      if (row < config.DATA_START_ROW) continue;

      // GitHub→Sheets更新による同期ロックがある行はスキップ
      if (hasSyncLock(row)) {
        log('Row has sync lock (GitHub update), skipping', { row });
        continue;
      }

      // 同期中の行は無視（ループ防止）
      const currentSyncStatus = getCellValue(sheet, row, HEADER_NAMES.SYNC_STATUS);
      if (currentSyncStatus === SYNC_STATUS.SYNCING) {
        log('Row is currently syncing, skipping', { row });
        continue;
      }

      // 同期実行
      try {
        syncRowToGitHub(row);
      } catch (err) {
        logError(`Failed to sync row ${row}`, err);
      }
    }

  } catch (e) {
    logError('onEditTrigger error', e);
  } finally {
    lock.releaseLock();
  }
}

/**
 * 編集範囲が無視対象列のみか判定
 * @param {number} startCol - 開始列
 * @param {number} numCols - 列数
 * @param {Array<number>} ignoredCols - 無視対象列
 * @returns {boolean} 無視対象列のみならtrue
 */
function isEditInIgnoredColumns(startCol, numCols, ignoredCols) {
  const endCol = startCol + numCols - 1;
  for (let col = startCol; col <= endCol; col++) {
    if (ignoredCols.indexOf(col) === -1) {
      return false;
    }
  }
  return true;
}

/**
 * 全ての未同期行を同期
 */
function syncAllToGitHub() {
  const sheet = getTargetSheet();
  const unsyncedRows = getUnsyncedRows(sheet);

  log('Starting full sync', { count: unsyncedRows.length });

  let success = 0;
  let failed = 0;

  unsyncedRows.forEach(({ row, data }) => {
    try {
      syncRowToGitHub(row);
      success++;
    } catch (e) {
      logError(`Failed to sync row ${row}`, e);
      failed++;
    }
  });

  log('Full sync completed', { success, failed });

  // 結果をUIに表示
  SpreadsheetApp.getUi().alert(
    '同期完了',
    `成功: ${success}件\n失敗: ${failed}件`,
    SpreadsheetApp.getUi().ButtonSet.OK
  );
}

/**
 * 選択中の行を同期
 */
function syncSelectedRow() {
  const sheet = SpreadsheetApp.getActive().getActiveSheet();
  const config = getConfig();

  if (sheet.getName() !== config.SHEET_NAME) {
    SpreadsheetApp.getUi().alert('エラー', `対象シート "${config.SHEET_NAME}" を選択してください。`, SpreadsheetApp.getUi().ButtonSet.OK);
    return;
  }

  const row = SpreadsheetApp.getActive().getActiveCell().getRow();

  if (row < config.DATA_START_ROW) {
    SpreadsheetApp.getUi().alert('エラー', 'データ行を選択してください。', SpreadsheetApp.getUi().ButtonSet.OK);
    return;
  }

  try {
    syncRowToGitHub(row);
    SpreadsheetApp.getUi().alert('完了', `行 ${row} を同期しました。`, SpreadsheetApp.getUi().ButtonSet.OK);
  } catch (e) {
    SpreadsheetApp.getUi().alert('エラー', `同期に失敗しました: ${e.message}`, SpreadsheetApp.getUi().ButtonSet.OK);
  }
}
