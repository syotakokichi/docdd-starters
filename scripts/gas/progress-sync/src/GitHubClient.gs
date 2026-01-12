/**
 * GitHubClient.gs - GitHub API クライアント
 *
 * GitHub REST API v3 を使用して Issue CRUD を実行
 */

/**
 * GitHub API リクエストを実行
 * @param {string} endpoint - APIエンドポイント（例: /repos/{owner}/{repo}/issues）
 * @param {string} method - HTTPメソッド
 * @param {Object} payload - リクエストボディ（オプション）
 * @returns {Object} レスポンスオブジェクト
 */
function githubRequest(endpoint, method = 'GET', payload = null) {
  const config = getConfig();

  if (!config.GITHUB_TOKEN) {
    throw new Error('GitHub Token が設定されていません。設定メニューから追加してください。');
  }

  const url = `${GITHUB_API_BASE}${endpoint}`;
  const options = {
    method: method,
    headers: {
      'Authorization': `token ${config.GITHUB_TOKEN}`,
      'Accept': 'application/vnd.github.v3+json',
      'Content-Type': 'application/json',
      'User-Agent': 'Progress-Sync-GAS'
    },
    muteHttpExceptions: true
  };

  if (payload && (method === 'POST' || method === 'PATCH' || method === 'PUT')) {
    options.payload = JSON.stringify(payload);
  }

  const response = UrlFetchApp.fetch(url, options);
  const statusCode = response.getResponseCode();
  const content = response.getContentText();

  if (statusCode >= 400) {
    log('GitHub API Error', { statusCode, content, endpoint });
    throw new Error(`GitHub API Error: ${statusCode} - ${content}`);
  }

  return content ? JSON.parse(content) : null;
}

/**
 * Issue を作成
 * @param {Object} issueData - Issue データ
 * @returns {Object} 作成された Issue
 */
function createIssue(issueData) {
  const config = getConfig();
  const endpoint = `/repos/${config.REPO_OWNER}/${config.REPO_NAME}/issues`;

  const payload = {
    title: issueData.title,
    body: issueData.body || '',
    labels: issueData.labels || [],
    assignees: issueData.assignees || []
  };

  log('Creating Issue', payload);
  return githubRequest(endpoint, 'POST', payload);
}

/**
 * Issue を更新
 * @param {number} issueNumber - Issue番号
 * @param {Object} updateData - 更新データ
 * @returns {Object} 更新された Issue
 */
function updateIssue(issueNumber, updateData) {
  const config = getConfig();
  const endpoint = `/repos/${config.REPO_OWNER}/${config.REPO_NAME}/issues/${issueNumber}`;

  log('Updating Issue', { issueNumber, updateData });
  return githubRequest(endpoint, 'PATCH', updateData);
}

/**
 * Issue をクローズ
 * @param {number} issueNumber - Issue番号
 * @returns {Object} 更新された Issue
 */
function closeIssue(issueNumber) {
  return updateIssue(issueNumber, { state: 'closed' });
}

/**
 * Issue をリオープン
 * @param {number} issueNumber - Issue番号
 * @returns {Object} 更新された Issue
 */
function reopenIssue(issueNumber) {
  return updateIssue(issueNumber, { state: 'open' });
}

/**
 * Issue を取得
 * @param {number} issueNumber - Issue番号
 * @returns {Object} Issue データ
 */
function getIssue(issueNumber) {
  const config = getConfig();
  const endpoint = `/repos/${config.REPO_OWNER}/${config.REPO_NAME}/issues/${issueNumber}`;
  return githubRequest(endpoint, 'GET');
}

/**
 * Issue の Labels を更新
 * @param {number} issueNumber - Issue番号
 * @param {Array<string>} labels - 新しい Labels
 * @returns {Object} 更新された Issue
 */
function setIssueLabels(issueNumber, labels) {
  const config = getConfig();
  const endpoint = `/repos/${config.REPO_OWNER}/${config.REPO_NAME}/issues/${issueNumber}/labels`;

  return githubRequest(endpoint, 'PUT', { labels });
}

/**
 * Label を作成（存在しない場合）
 * @param {Object} labelData - { name, color, description }
 * @returns {Object|null} 作成された Label または null（既存の場合）
 */
function createLabelIfNotExists(labelData) {
  const config = getConfig();
  const endpoint = `/repos/${config.REPO_OWNER}/${config.REPO_NAME}/labels`;

  try {
    return githubRequest(endpoint, 'POST', labelData);
  } catch (e) {
    // 422: 既に存在する場合は無視
    if (e.message.includes('422')) {
      log('Label already exists', labelData.name);
      return null;
    }
    throw e;
  }
}

/**
 * 必要な Labels を全て作成
 */
function createRequiredLabels() {
  const labels = getRequiredLabels();
  let created = 0;
  let skipped = 0;

  labels.forEach(label => {
    try {
      const result = createLabelIfNotExists(label);
      if (result) {
        created++;
      } else {
        skipped++;
      }
    } catch (e) {
      logError(`Failed to create label: ${label.name}`, e);
    }
  });

  log('Labels creation completed', { created, skipped });
  return { created, skipped };
}

/**
 * Issue Body を生成
 * @param {Object} rowData - 行データオブジェクト
 * @returns {string} Issue Body (Markdown)
 */
function generateIssueBody(rowData) {
  const lines = [
    '## タスク概要',
    '',
    `**カテゴリ**: ${rowData[HEADER_NAMES.CATEGORY] || '未設定'}`,
    `**担当**: ${rowData[HEADER_NAMES.ASSIGNEE] || '未設定'}`,
    `**工数**: ${rowData[HEADER_NAMES.EFFORT] || '未設定'}人日`,
    '',
    '## スケジュール',
    '',
    `- **開始日**: ${formatDate(rowData[HEADER_NAMES.START_DATE]) || '未設定'}`,
    `- **終了日**: ${formatDate(rowData[HEADER_NAMES.END_DATE]) || '未設定'}`,
    ''
  ];

  if (rowData[HEADER_NAMES.DEPENDENCY]) {
    lines.push('## 依存関係', '', rowData[HEADER_NAMES.DEPENDENCY], '');
  }

  if (rowData[HEADER_NAMES.NOTE]) {
    lines.push('## 備考', '', rowData[HEADER_NAMES.NOTE], '');
  }

  lines.push(
    '---',
    '',
    '_このIssueはGoogle Sheetsから自動生成されました。_'
  );

  return lines.join('\n');
}

/**
 * 行データからLabelsを生成
 * @param {Object} rowData - 行データオブジェクト
 * @returns {Array<string>} Labels配列
 */
function generateLabelsFromRow(rowData) {
  const labels = [];

  // カテゴリをラベルに変換（必要に応じてカスタマイズ）
  const category = rowData[HEADER_NAMES.CATEGORY];
  if (category) {
    // カテゴリ名をラベル形式に変換（スペースをハイフンに、小文字に）
    const categoryLabel = category.toLowerCase().replace(/\s+/g, '-');
    labels.push(`category:${categoryLabel}`);
  }

  return labels;
}

/**
 * 担当者文字列を GitHub assignees 配列に変換
 * @param {string} assignee - 担当者文字列
 * @returns {Array<string>} GitHub ユーザー名配列
 */
function parseAssignees(assignee) {
  // TODO: 担当者名 → GitHubユーザー名のマッピングテーブルを設定可能にする
  // 現時点では空配列を返す（GitHubユーザー名とシート上の名前が異なるため）
  return [];
}
