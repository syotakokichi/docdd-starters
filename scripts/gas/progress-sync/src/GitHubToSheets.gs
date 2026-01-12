/**
 * GitHubToSheets.gs - GitHub → Sheets 同期（Webhook受信）
 *
 * GitHub Webhook からの Issue/PR イベントを受信し、
 * Sheets のステータスを更新
 *
 * 注意: GAS Web App ではHTTPヘッダにアクセスできないため、
 * 署名検証は行わず、URLの秘匿性でセキュリティを担保
 */

/**
 * Webhook エンドポイント（Web App として公開）
 * @param {Object} e - リクエストオブジェクト
 * @returns {TextOutput} レスポンス
 */
function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      log('Webhook payload missing');
      return ContentService.createTextOutput('No payload')
        .setMimeType(ContentService.MimeType.TEXT);
    }

    // ペイロード解析
    const payload = JSON.parse(e.postData.contents);

    // イベントタイプをペイロードから推測
    const event = detectEventType(payload);
    const eventKey = getEventKeyFromPayload(payload);

    // 冪等性チェック（二重処理防止）
    if (eventKey && isAlreadyProcessed(eventKey)) {
      log('Event already processed', { eventKey });
      return ContentService.createTextOutput('Already processed')
        .setMimeType(ContentService.MimeType.TEXT);
    }

    log('Webhook received', { event, action: payload.action, eventKey });

    // イベント処理
    switch (event) {
      case 'issues':
        handleIssueEvent(payload);
        break;
      case 'pull_request':
        handlePullRequestEvent(payload);
        break;
      default:
        log('Unhandled event type', { event });
    }

    if (eventKey) {
      markAsProcessed(eventKey);
    }

    return ContentService.createTextOutput('OK')
      .setMimeType(ContentService.MimeType.TEXT);

  } catch (error) {
    logError('Webhook processing error', error);
    return ContentService.createTextOutput('Error: ' + error.message)
      .setMimeType(ContentService.MimeType.TEXT);
  }
}

/**
 * ペイロードからイベントタイプを推測
 * GAS Web AppではHTTPヘッダにアクセスできないため、
 * ペイロードの構造からイベントタイプを判定
 * @param {Object} payload - Webhook ペイロード
 * @returns {string} イベントタイプ
 */
function detectEventType(payload) {
  if (payload.issue && !payload.pull_request) {
    return 'issues';
  }
  if (payload.pull_request) {
    return 'pull_request';
  }
  if (payload.repository && payload.pusher) {
    return 'push';
  }
  return 'unknown';
}

/**
 * ペイロードからイベントキーを生成
 * @param {Object} payload - Webhook ペイロード
 * @returns {string|null} イベントキー
 */
function getEventKeyFromPayload(payload) {
  if (payload.pull_request && payload.pull_request.id) {
    return `pr:${payload.pull_request.id}:${payload.action || ''}`;
  }
  if (payload.issue && payload.issue.id) {
    return `issue:${payload.issue.id}:${payload.action || ''}`;
  }
  return null;
}

/**
 * イベントが処理済みかチェック
 * @param {string} eventKey - イベントキー
 * @returns {boolean} 処理済みならtrue
 */
function isAlreadyProcessed(eventKey) {
  const cache = CacheService.getScriptCache();
  return cache.get('processed_' + eventKey) !== null;
}

/**
 * イベントを処理済みとしてマーク
 * @param {string} eventKey - イベントキー
 */
function markAsProcessed(eventKey) {
  const cache = CacheService.getScriptCache();
  // 6時間有効
  cache.put('processed_' + eventKey, 'true', 21600);
}

/**
 * Issue イベントを処理
 * @param {Object} payload - Webhook ペイロード
 */
function handleIssueEvent(payload) {
  const { action, issue } = payload;
  const issueNumber = issue.number;

  log('Handling issue event', { action, issueNumber });

  const sheet = getTargetSheet();
  const row = findRowByIssueNumber(sheet, issueNumber);

  if (!row) {
    log('Issue not found in sheet', { issueNumber });
    return;
  }

  // アクションに応じてステータスを更新
  const newStatus = mapGitHubActionToStatus(action);
  if (newStatus) {
    // 同期ロックを設定（onEditトリガーを抑止）
    setSyncLock(row);
    updateRowStatus(sheet, row, newStatus);
    setCellValue(sheet, row, HEADER_NAMES.SYNC_STATUS, SYNC_STATUS.SYNCED);
    log('Updated row status', { row, newStatus });
  }
}

/**
 * Pull Request イベントを処理
 * @param {Object} payload - Webhook ペイロード
 */
function handlePullRequestEvent(payload) {
  const { action, pull_request } = payload;
  const prNumber = pull_request.number;
  const prBody = pull_request.body || '';

  log('Handling PR event', { action, prNumber });

  // "closes #XXX" パターンで紐づく Issue を検索
  const issueMatches = prBody.match(/closes?\s+#(\d+)/gi);
  if (!issueMatches) {
    log('No linked issues found in PR body');
    return;
  }

  const sheet = getTargetSheet();

  issueMatches.forEach(match => {
    const issueNumber = parseInt(match.replace(/\D/g, ''), 10);
    const row = findRowByIssueNumber(sheet, issueNumber);

    if (row) {
      // 同期ロックを設定（onEditトリガーを抑止）
      setSyncLock(row);

      // PR 番号を記録
      setCellValue(sheet, row, HEADER_NAMES.PR_NUMBER, prNumber);

      // マージされた場合はステータスを完了に
      if (action === 'closed' && pull_request.merged) {
        updateRowStatus(sheet, row, '完了');
        setCellValue(sheet, row, HEADER_NAMES.SYNC_STATUS, SYNC_STATUS.SYNCED);
        log('PR merged, updated issue to completed', { issueNumber, prNumber });
      }
    }
  });
}

/**
 * Webhook テスト用（手動実行）
 */
function testWebhook() {
  const testPayload = {
    action: 'closed',
    issue: {
      number: 1,
      title: 'Test Issue'
    }
  };

  log('Testing webhook handler', testPayload);

  try {
    handleIssueEvent(testPayload);
    log('Webhook test completed successfully');
  } catch (e) {
    logError('Webhook test failed', e);
  }
}
