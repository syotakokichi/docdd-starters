/**
 * Main.gs - エントリーポイント・メニュー・トリガー設定
 *
 * Progress Sync - Google Sheets ↔ GitHub Issues 双方向同期
 */

/**
 * スプレッドシートを開いたときにメニューを追加
 */
function onOpen() {
  const ui = SpreadsheetApp.getUi();
  ui.createMenu('進捗同期')
    .addItem('GitHubと同期', 'syncAllToGitHub')
    .addItem('選択行を同期', 'syncSelectedRow')
    .addSeparator()
    .addItem('必要なLabelsを作成', 'createRequiredLabelsWithUI')
    .addItem('必要な列を追加', 'ensureRequiredColumnsWithUI')
    .addSeparator()
    .addItem('トリガーを設定', 'setupTriggersWithUI')
    .addItem('設定', 'showConfigDialog')
    .addToUi();
}

/**
 * インストール型トリガーを設定
 */
function setupTriggers() {
  // 既存トリガーを削除
  const triggers = ScriptApp.getProjectTriggers();
  triggers.forEach(t => {
    if (t.getHandlerFunction() === 'onEditTrigger') {
      ScriptApp.deleteTrigger(t);
    }
  });

  // 新しいトリガーを設定
  ScriptApp.newTrigger('onEditTrigger')
    .forSpreadsheet(SpreadsheetApp.getActive())
    .onEdit()
    .create();

  log('Triggers configured');
}

/**
 * トリガー設定（UI付き）
 */
function setupTriggersWithUI() {
  try {
    setupTriggers();
    SpreadsheetApp.getUi().alert(
      '完了',
      'onEdit トリガーを設定しました。\n行の編集時に自動同期されます。',
      SpreadsheetApp.getUi().ButtonSet.OK
    );
  } catch (e) {
    SpreadsheetApp.getUi().alert(
      'エラー',
      `トリガー設定に失敗しました: ${e.message}`,
      SpreadsheetApp.getUi().ButtonSet.OK
    );
  }
}

/**
 * 必要なLabelsを作成（UI付き）
 */
function createRequiredLabelsWithUI() {
  try {
    const result = createRequiredLabels();
    SpreadsheetApp.getUi().alert(
      '完了',
      `Labels作成完了\n新規作成: ${result.created}件\n既存: ${result.skipped}件`,
      SpreadsheetApp.getUi().ButtonSet.OK
    );
  } catch (e) {
    SpreadsheetApp.getUi().alert(
      'エラー',
      `Labels作成に失敗しました: ${e.message}\n\nGitHub Tokenが設定されているか確認してください。`,
      SpreadsheetApp.getUi().ButtonSet.OK
    );
  }
}

/**
 * 必要な列を追加（UI付き）
 */
function ensureRequiredColumnsWithUI() {
  try {
    const sheet = getTargetSheet();
    ensureRequiredColumns(sheet);
    SpreadsheetApp.getUi().alert(
      '完了',
      '必要な列を追加しました。\n- Issue番号\n- PR番号\n- 同期ステータス',
      SpreadsheetApp.getUi().ButtonSet.OK
    );
  } catch (e) {
    SpreadsheetApp.getUi().alert(
      'エラー',
      `列の追加に失敗しました: ${e.message}`,
      SpreadsheetApp.getUi().ButtonSet.OK
    );
  }
}

/**
 * 初期セットアップ（全ての設定を一括で行う）
 */
function initialSetup() {
  const ui = SpreadsheetApp.getUi();

  // 設定確認
  const config = getConfig();
  if (!config.GITHUB_TOKEN) {
    ui.alert(
      '設定が必要です',
      'まず「設定」メニューからGitHub Tokenを設定してください。',
      ui.ButtonSet.OK
    );
    showConfigDialog();
    return;
  }

  // 確認ダイアログ
  const response = ui.alert(
    '初期セットアップ',
    '以下の処理を実行します:\n\n' +
    '1. 必要な列を追加（Issue番号, PR番号, 同期ステータス）\n' +
    '2. GitHub Labelsを作成\n' +
    '3. onEditトリガーを設定\n\n' +
    '続行しますか？',
    ui.ButtonSet.YES_NO
  );

  if (response !== ui.Button.YES) {
    return;
  }

  try {
    // 1. 必要な列を追加
    const sheet = getTargetSheet();
    ensureRequiredColumns(sheet);
    log('Required columns added');

    // 2. GitHub Labelsを作成
    const labelResult = createRequiredLabels();
    log('Labels created', labelResult);

    // 3. トリガーを設定
    setupTriggers();
    log('Triggers configured');

    ui.alert(
      'セットアップ完了',
      '初期セットアップが完了しました。\n\n' +
      `Labels: 新規 ${labelResult.created}件, 既存 ${labelResult.skipped}件\n` +
      'トリガー: 設定済み\n\n' +
      '行を編集すると自動的にGitHub Issueと同期されます。',
      ui.ButtonSet.OK
    );

  } catch (e) {
    logError('Initial setup failed', e);
    ui.alert(
      'エラー',
      `セットアップに失敗しました: ${e.message}`,
      ui.ButtonSet.OK
    );
  }
}

/**
 * Web App エンドポイント（GET）- ヘルスチェック用
 */
function doGet(e) {
  return ContentService.createTextOutput(JSON.stringify({
    status: 'ok',
    message: 'Progress Sync Webhook is running',
    timestamp: new Date().toISOString()
  })).setMimeType(ContentService.MimeType.JSON);
}
