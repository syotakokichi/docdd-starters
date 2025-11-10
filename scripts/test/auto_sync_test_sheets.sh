#!/bin/bash
#
# Google Sheets テスト自動同期スクリプト
# 環境チェック・依存関係解決・同期実行を一括で行う
#
# Usage:
#   scripts/test/auto_sync_test_sheets.sh [options]
#
# Options:
#   --force-install   依存関係を強制再インストール
#   --setup-only      セットアップのみ実行（同期なし）
#   --check-only      環境チェックのみ実行
#   --dry-run         ドライランモード（実際の同期なし）
#   --verbose         詳細ログ出力
#   --help            ヘルプ表示
#

set -e  # エラーで即座に終了

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ルートに .env があれば読み込む
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$PROJECT_ROOT/.env"
    set +a
fi

# デフォルト設定
FORCE_INSTALL=false
SETUP_ONLY=false
CHECK_ONLY=false
DRY_RUN=false
VERBOSE=false
PROJECT_NAME="${PROJECT_NAME:-DocDD Starter Project}"
SECRET_ARN="${TEST_SHEETS_SECRET_ARN:-your-secret-arn}"
SPREADSHEET_ID="${TEST_SPREADSHEET_ID:-your-spreadsheet-id}"

# ログ関数
log_info() {
    echo -e "${BLUE}ℹ${NC}  $1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

log_error() {
    echo -e "${RED}❌${NC} $1"
}

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}🔍${NC} $1"
    fi
}

# ヘルプ表示
show_help() {
    cat << EOF
Google Sheets テスト自動同期スクリプト

Usage:
    scripts/test/auto_sync_test_sheets.sh [options]

Options:
    --force-install   依存関係を強制再インストール
    --setup-only      セットアップのみ実行（同期なし）
    --check-only      環境チェックのみ実行
    --dry-run         ドライランモード（実際の同期なし）
    --verbose         詳細ログ出力
    --secret-arn ARN  使用する AWS Secrets Manager の ARN（環境変数 TEST_SHEETS_SECRET_ARN を上書き）
    --spreadsheet-id  Google Spreadsheet ID（Secret 側で管理する場合は省略可）
    --help            このヘルプを表示

Examples:
    # 通常実行
    scripts/test/auto_sync_test_sheets.sh

    # 初回実行（依存関係インストール）
    scripts/test/auto_sync_test_sheets.sh --force-install

    # 環境チェックのみ
    scripts/test/auto_sync_test_sheets.sh --check-only

    # ドライラン
    scripts/test/auto_sync_test_sheets.sh --dry-run --verbose

EOF
    exit 0
}

# コマンドライン引数の解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --force-install)
            FORCE_INSTALL=true
            shift
            ;;
        --setup-only)
            SETUP_ONLY=true
            shift
            ;;
        --check-only)
            CHECK_ONLY=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --secret-arn)
            if [ -z "${2:-}" ]; then
                log_error "--secret-arn オプションには値が必要です"
                exit 1
            fi
            SECRET_ARN="$2"
            shift 2
            ;;
        --spreadsheet-id)
            if [ -z "${2:-}" ]; then
                log_error "--spreadsheet-id オプションには値が必要です"
                exit 1
            fi
            SPREADSHEET_ID="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# ====================================================================
# 環境チェック
# ====================================================================

log_info "環境チェックを開始します..."

# Python バージョンチェック
check_python() {
    log_verbose "Python バージョンを確認中..."

    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 がインストールされていません"
        log_warning "解決方法: brew install python3"
        exit 1
    fi

    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d'.' -f1)
    PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d'.' -f2)

    if [ "$PYTHON_MAJOR" -lt 3 ] || { [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]; }; then
        log_error "Python 3.8 以上が必要です（現在: $PYTHON_VERSION）"
        exit 1
    fi

    log_success "Python $PYTHON_VERSION"
}

# AWS 認証チェック
check_aws_auth() {
    log_verbose "AWS 認証情報を確認中..."

    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI がインストールされていません"
        log_warning "解決方法: brew install awscli"
        exit 1
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS 認証に失敗しました"
        log_warning "解決方法:"
        log_warning "  1. aws configure で認証情報を設定"
        log_warning "  2. aws sts get-caller-identity で認証状況を確認"
        exit 1
    fi

    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
    log_success "AWS 認証済み (Account: ${AWS_ACCOUNT:0:4}****)"
}

# venv チェック
check_venv() {
    log_verbose "Python 仮想環境を確認中..."

    VENV_PATH="$PROJECT_ROOT/apps/backend/venv"

    if [ ! -d "$VENV_PATH" ]; then
        log_warning "仮想環境が見つかりません。作成します..."
        cd "$PROJECT_ROOT/apps/backend"
        python3 -m venv venv
        log_success "仮想環境を作成しました: $VENV_PATH"
    else
        log_success "仮想環境: $VENV_PATH"
    fi

    # venv の Python を使用
    export PYTHON_BIN="$VENV_PATH/bin/python3"
    export PIP_BIN="$VENV_PATH/bin/pip3"
}

# 依存関係チェック
check_dependencies() {
    log_verbose "依存関係を確認中..."

    REQUIRED_PACKAGES=(
        "google-api-python-client"
        "google-auth"
        "boto3"
        "gspread"
        "pyyaml"
    )

    MISSING_PACKAGES=()

    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! "$PYTHON_BIN" -c "import ${package//-/_}" &> /dev/null 2>&1; then
            MISSING_PACKAGES+=("$package")
        fi
    done

    if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        log_warning "不足している依存関係: ${MISSING_PACKAGES[*]}"
        return 1
    fi

    log_success "すべての依存関係がインストール済み"
    return 0
}

# ====================================================================
# セットアップ
# ====================================================================

install_dependencies() {
    log_info "依存関係をインストール中..."

    PACKAGES=(
        "google-api-python-client>=2.147.0"
        "google-auth>=2.40.0"
        "boto3>=1.35.0"
        "gspread>=6.2.0"
        "pyyaml>=6.0.0"
    )

    if [ "$FORCE_INSTALL" = true ]; then
        log_verbose "強制再インストールモード"
        "$PIP_BIN" install --upgrade --force-reinstall "${PACKAGES[@]}"
    else
        "$PIP_BIN" install --upgrade "${PACKAGES[@]}"
    fi

    log_success "依存関係のインストールが完了しました"
}

# ====================================================================
# Google Sheets 同期実行
# ====================================================================

run_sync() {
    log_info "Google Sheets 同期を開始します..."

    SYNC_SCRIPT="$SCRIPT_DIR/enhanced_sheets_sync.py"

    if [ ! -f "$SYNC_SCRIPT" ]; then
        log_error "同期スクリプトが見つかりません: $SYNC_SCRIPT"
        exit 1
    fi

    if [ -z "$SECRET_ARN" ] || [ "$SECRET_ARN" = "your-secret-arn" ]; then
        log_error "Secret ARN がプレースホルダのままです。"
        log_warning "  export TEST_SHEETS_SECRET_ARN=\"arn:aws:secretsmanager:...\""
        log_warning "  または --secret-arn で明示的に指定してください"
        exit 1
    fi

    SYNC_ARGS=(
        "--secret-arn=$SECRET_ARN"
    )

    if [ -n "$SPREADSHEET_ID" ] && [ "$SPREADSHEET_ID" != "your-spreadsheet-id" ]; then
        SYNC_ARGS+=("--spreadsheet-id=$SPREADSHEET_ID")
    fi

    if [ "$DRY_RUN" = true ]; then
        log_warning "ドライランモード: 実際の同期は行いません"
        SYNC_ARGS+=("--dry-run")
    fi

    if [ "$VERBOSE" = true ]; then
        SYNC_ARGS+=("--verbose")
    fi

    log_verbose "実行コマンド: $PYTHON_BIN $SYNC_SCRIPT ${SYNC_ARGS[*]}"

    if "$PYTHON_BIN" "$SYNC_SCRIPT" "${SYNC_ARGS[@]}"; then
        log_success "Google Sheets 同期が完了しました"
        return 0
    else
        log_error "Google Sheets 同期に失敗しました"
        return 1
    fi
}

# ====================================================================
# メイン処理
# ====================================================================

main() {
    echo ""
    log_info "======================================================================"
    log_info "Google Sheets テスト自動同期 (${PROJECT_NAME})"
    log_info "======================================================================"
    echo ""

    # 環境チェック
    check_python
    check_aws_auth
    check_venv

    if [ "$CHECK_ONLY" = true ]; then
        log_info "環境チェックのみ実行します"
        if check_dependencies; then
            log_success "環境チェック完了: すべてOK"
            exit 0
        else
            log_warning "依存関係が不足しています"
            log_info "解決方法: scripts/test/auto_sync_test_sheets.sh --force-install"
            exit 1
        fi
    fi

    # 依存関係チェック・インストール
    if ! check_dependencies || [ "$FORCE_INSTALL" = true ]; then
        install_dependencies
    fi

    if [ "$SETUP_ONLY" = true ]; then
        log_success "セットアップ完了"
        exit 0
    fi

    # Google Sheets 同期実行
    if run_sync; then
        echo ""
        log_success "======================================================================"
        log_success "同期処理が正常に完了しました"
        log_success "======================================================================"
        echo ""
        log_info "Google Sheets でテスト管理シートを確認してください"
        echo ""
        exit 0
    else
        echo ""
        log_error "======================================================================"
        log_error "同期処理に失敗しました"
        log_error "======================================================================"
        echo ""
        log_warning "トラブルシューティング:"
        log_warning "  1. 詳細ログ: scripts/test/auto_sync_test_sheets.sh --verbose"
        log_warning "  2. 環境確認: scripts/test/auto_sync_test_sheets.sh --check-only"
        log_warning "  3. 再インストール: scripts/test/auto_sync_test_sheets.sh --force-install"
        echo ""
        exit 1
    fi
}

# スクリプト実行
main
