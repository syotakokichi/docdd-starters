/**
 * Config.gs - 設定・定数管理
 *
 * PropertiesService で機密情報を管理
 * ヘッダ名でSheets列を動的取得
 */

// =====================================================
// Sheets ヘッダ名定義（列指定はヘッダ名基準）
// プロジェクトに合わせてカスタマイズしてください
// =====================================================
const HEADER_NAMES = {
  CATEGORY: 'カテゴリ',
  TASK: 'タスク',
  ASSIGNEE: '担当',
  EFFORT: '工数(人日)',
  START_DATE: '開始日',
  END_DATE: '終了日',
  STATUS: 'ステータス',
  DEPENDENCY: '依存関係',
  NOTE: '備考',
  ISSUE_NUMBER: 'Issue番号',
  PR_NUMBER: 'PR番号',
  SYNC_STATUS: '同期ステータス'
};

// =====================================================
// 同期対象外のステータス値
// =====================================================
const SKIP_STATUS_VALUES = [
  '対象外',
  '中リスク',
  '低リスク',
  '高リスク'
];

// =====================================================
// 同期ステータス値
// =====================================================
const SYNC_STATUS = {
  SYNCED: '同期済み',
  NOT_SYNCED: '未同期',
  ERROR: 'エラー',
  SYNCING: '同期中'
};

// =====================================================
// GitHub API 設定
// =====================================================
const GITHUB_API_BASE = 'https://api.github.com';

/**
 * 設定を取得（PropertiesService から）
 * @returns {Object} 設定オブジェクト
 */
function getConfig() {
  const props = PropertiesService.getScriptProperties();
  return {
    GITHUB_TOKEN: props.getProperty('GITHUB_TOKEN') || '',
    REPO_OWNER: props.getProperty('REPO_OWNER') || '',
    REPO_NAME: props.getProperty('REPO_NAME') || '',
    WEBHOOK_SECRET: props.getProperty('WEBHOOK_SECRET') || '',
    SHEET_NAME: props.getProperty('SHEET_NAME') || 'タスク一覧',
    HEADER_ROW: parseInt(props.getProperty('HEADER_ROW') || '1', 10),
    DATA_START_ROW: parseInt(props.getProperty('DATA_START_ROW') || '2', 10)
  };
}

/**
 * 設定を保存（PropertiesService へ）
 * @param {Object} config - 設定オブジェクト
 */
function setConfig(config) {
  const props = PropertiesService.getScriptProperties();
  Object.entries(config).forEach(([key, value]) => {
    if (value !== undefined && value !== null) {
      props.setProperty(key, String(value));
    }
  });
}

/**
 * 設定ダイアログを表示
 */
function showConfigDialog() {
  const html = HtmlService.createHtmlOutputFromFile('ConfigDialog')
    .setWidth(400)
    .setHeight(350);
  SpreadsheetApp.getUi().showModalDialog(html, '進捗同期 設定');
}

/**
 * 必要なLabels定義を取得
 * @returns {Array<Object>} Labels定義配列
 */
function getRequiredLabels() {
  return [
    { name: 'status:todo', color: 'e6e6e6', description: '未着手' },
    { name: 'status:in-progress', color: '0e8a16', description: '進行中' },
    { name: 'status:on-hold', color: 'fbca04', description: '保留' }
  ];
}
