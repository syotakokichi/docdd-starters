/**
 * StatusMapping.gs - ステータス ↔ GitHub Issue State 変換
 */

// =====================================================
// Sheets ステータス → GitHub Issue 状態
// =====================================================
const STATUS_TO_GITHUB = {
  '未着手': { state: 'open', label: 'status:todo' },
  '進行中': { state: 'open', label: 'status:in-progress' },
  '完了': { state: 'closed', label: null },
  '保留': { state: 'open', label: 'status:on-hold' }
};

// =====================================================
// GitHub → Sheets ステータス
// =====================================================
const GITHUB_ACTION_TO_STATUS = {
  'closed': '完了',
  'reopened': '進行中'
};

/**
 * Sheetsステータスが同期対象外かチェック
 * 空欄は「未着手」として同期対象とする
 * @param {string} status - Sheetsステータス
 * @returns {boolean} 同期対象外ならtrue
 */
function isSkipStatus(status) {
  // 空欄は同期対象（未着手として扱う）
  if (!status) return false;
  return SKIP_STATUS_VALUES.includes(status.trim());
}

/**
 * SheetsステータスからGitHub Issue状態を取得
 * @param {string} status - Sheetsステータス
 * @returns {Object} { state: 'open'|'closed', label: string|null }
 */
function mapStatusToGitHub(status) {
  if (!status) return { state: 'open', label: 'status:todo' };
  const normalized = status.trim();
  return STATUS_TO_GITHUB[normalized] || { state: 'open', label: 'status:todo' };
}

/**
 * GitHub IssueアクションからSheetsステータスを取得
 * @param {string} action - GitHub Issue action (closed, reopened, etc.)
 * @returns {string|null} Sheetsステータス、該当なしならnull
 */
function mapGitHubActionToStatus(action) {
  return GITHUB_ACTION_TO_STATUS[action] || null;
}

/**
 * ステータスラベルを除去したLabels配列を返す
 * @param {Array<string>} labels - GitHub Labels
 * @returns {Array<string>} ステータスラベルを除いたLabels
 */
function removeStatusLabels(labels) {
  if (!labels || !Array.isArray(labels)) return [];
  return labels.filter(label => !label.startsWith('status:'));
}

/**
 * ステータスに応じたLabelを追加したLabels配列を返す
 * @param {Array<string>} labels - 現在のLabels
 * @param {string} status - Sheetsステータス
 * @returns {Array<string>} 更新後のLabels
 */
function updateStatusLabel(labels, status) {
  const cleaned = removeStatusLabels(labels);
  const githubStatus = mapStatusToGitHub(status);
  if (githubStatus.label) {
    cleaned.push(githubStatus.label);
  }
  return cleaned;
}

/**
 * Issue がオープン状態かどうかを判定
 * @param {string} status - Sheetsステータス
 * @returns {boolean} オープンならtrue
 */
function isOpenStatus(status) {
  const githubStatus = mapStatusToGitHub(status);
  return githubStatus.state === 'open';
}
