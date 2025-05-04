#!/bin/bash

# 設定ファイルのパス
# スクリプト名をベースにした設定ファイル名を生成
SCRIPT_NAME=$(basename "$0" .command)
CONFIG_FILE="$HOME/.${SCRIPT_NAME}_settings.conf"

# 色の設定
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 設定1: プロジェクトルートディレクトリの取得と保存
get_project_root() {
    if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ] || ! grep -q "PROJECT_ROOT=" "$CONFIG_FILE"; then
        echo -e "${YELLOW}プロジェクトルートディレクトリの絶対パスを入力してください:${NC}"
        read project_root
        
        # 設定ファイルがなければ作成
        if [ ! -f "$CONFIG_FILE" ]; then
            touch "$CONFIG_FILE"
        fi
        
        # 既存の設定を削除して新しい設定を追加
        sed -i '' '/PROJECT_ROOT=/d' "$CONFIG_FILE" 2>/dev/null
        echo "PROJECT_ROOT=$project_root" >> "$CONFIG_FILE"
        echo -e "${GREEN}プロジェクトルートディレクトリが保存されました${NC}"
    fi
    
    # 設定を読み込む
    source "$CONFIG_FILE"
    return 0
}

# 設定2: 開きたいプロジェクトページの取得と保存
get_project_page() {
    if [ ! -f "$CONFIG_FILE" ] || ! grep -q "PROJECT_PAGE=" "$CONFIG_FILE"; then
        echo -e "${YELLOW}開きたいプロジェクトのページを入力してください（例: index.html）:${NC}"
        read project_page
        
        # 既存の設定を削除して新しい設定を追加
        sed -i '' '/PROJECT_PAGE=/d' "$CONFIG_FILE" 2>/dev/null
        echo "PROJECT_PAGE=$project_page" >> "$CONFIG_FILE"
        echo -e "${GREEN}プロジェクトページが保存されました${NC}"
    fi
    
    # 設定を読み込む
    source "$CONFIG_FILE"
    return 0
}

# 設定3: URLの取得と保存
get_reference_url() {
    if [ ! -f "$CONFIG_FILE" ] || ! grep -q "REFERENCE_URL=" "$CONFIG_FILE"; then
        echo -e "${YELLOW}Chromeで開きたい仕様書やリファレンスなどのURLがありますか？ (Y/N):${NC}"
        read has_url
        
        if [[ $has_url == "Y" || $has_url == "y" ]]; then
            echo -e "${YELLOW}URLを入力してください:${NC}"
            read reference_url
            
            # 既存の設定を削除して新しい設定を追加
            sed -i '' '/REFERENCE_URL=/d' "$CONFIG_FILE" 2>/dev/null
            echo "REFERENCE_URL=$reference_url" >> "$CONFIG_FILE"
            echo -e "${GREEN}リファレンスURLが保存されました${NC}"
        else
            # URLがない場合は空に設定
            sed -i '' '/REFERENCE_URL=/d' "$CONFIG_FILE" 2>/dev/null
            echo "REFERENCE_URL=" >> "$CONFIG_FILE"
            echo -e "${GREEN}プロジェクトを開始します${NC}"
        fi
    fi
    
    # 設定を読み込む
    source "$CONFIG_FILE"
    return 0
}

# 設定4: コマンドファイルの取得と保存
get_command_file() {
    if [ ! -f "$CONFIG_FILE" ] || ! grep -q "COMMAND_FILE=" "$CONFIG_FILE"; then
        echo -e "${YELLOW}叩いて欲しいコマンドファイルがありますか？ (Y/N):${NC}"
        read has_command
        
        if [[ $has_command == "Y" || $has_command == "y" ]]; then
            echo -e "${YELLOW}コマンドファイルのパスを入力してください:${NC}"
            read command_file
            
            # 既存の設定を削除して新しい設定を追加
            sed -i '' '/COMMAND_FILE=/d' "$CONFIG_FILE" 2>/dev/null
            echo "COMMAND_FILE=$command_file" >> "$CONFIG_FILE"
            echo -e "${GREEN}コマンドファイルが保存されました${NC}"
        else
            # コマンドファイルがない場合は空に設定
            sed -i '' '/COMMAND_FILE=/d' "$CONFIG_FILE" 2>/dev/null
            echo "COMMAND_FILE=" >> "$CONFIG_FILE"
            echo -e "${GREEN}プロジェクトを開始します${NC}"
        fi
    fi
    
    # 設定を読み込む
    source "$CONFIG_FILE"
    return 0
}

# 設定の更新
update_setting() {
    case $1 in
        1)
            sed -i '' '/PROJECT_ROOT=/d' "$CONFIG_FILE" 2>/dev/null
            get_project_root
            ;;
        2)
            sed -i '' '/PROJECT_PAGE=/d' "$CONFIG_FILE" 2>/dev/null
            get_project_page
            ;;
        3)
            sed -i '' '/REFERENCE_URL=/d' "$CONFIG_FILE" 2>/dev/null
            get_reference_url
            ;;
        4)
            sed -i '' '/COMMAND_FILE=/d' "$CONFIG_FILE" 2>/dev/null
            get_command_file
            ;;
        *)
            echo -e "${YELLOW}無効な入力です。以下から選択してください:${NC}"
            echo -e "1: プロジェクトルートディレクトリ"
            echo -e "2: 開きたいページ"
            echo -e "3: 開きたいURL"
            echo -e "4: 叩きたいコマンドファイル"
            ;;
    esac
    
    echo -e "${GREEN}設定は保存されました${NC}"
}

# サーバープロセスをクリーンアップする関数
cleanup() {
    echo -e "${YELLOW}サーバーを停止しています...${NC}"
    # ポート5502で実行中のプロセスを検索して終了
    SERVER_PID=$(lsof -ti:5502)
    if [ ! -z "$SERVER_PID" ]; then
        kill -9 $SERVER_PID 2>/dev/null
    fi
    echo -e "${GREEN}クリーンアップ完了${NC}"
    exit 0
}

# 終了時にクリーンアップを実行するよう設定
trap cleanup EXIT INT TERM

# メインの処理
main() {
    # 各設定を取得
    get_project_root
    get_project_page
    get_reference_url
    get_command_file
    
    # 既存のサーバープロセスをクリーンアップ
    SERVER_PID=$(lsof -ti:5502)
    if [ ! -z "$SERVER_PID" ]; then
        echo -e "${YELLOW}既存のサーバーを停止しています...${NC}"
        kill -9 $SERVER_PID 2>/dev/null
        sleep 1
    fi
    
    # プロジェクトを開始
    echo -e "${GREEN}プロジェクトを開始します...${NC}"
    
    # 5. Cursorでプロジェクトを開き、簡易サーバーを起動する
    echo -e "${BLUE}プロジェクトをCursorで開きます...${NC}"
    open -a "Cursor" "$PROJECT_ROOT"
    
    # 簡易HTTPサーバーを起動（バックグラウンドで）
    echo -e "${YELLOW}簡易HTTPサーバーを起動しています...${NC}"
    
    # カレントディレクトリをプロジェクトルートに変更
    cd "$PROJECT_ROOT"
    echo -e "${YELLOW}現在のディレクトリ: $(pwd)${NC}"
    echo -e "${YELLOW}ファイルの存在を確認: ${PROJECT_PAGE}${NC}"
    if [ -f "$PROJECT_PAGE" ]; then
        echo -e "${GREEN}ファイルが見つかりました${NC}"
    else
        echo -e "${YELLOW}注意: ${PROJECT_PAGE} が見つかりません。パスを確認してください。${NC}"
        # ファイル一覧を表示
        echo -e "${YELLOW}現在のディレクトリのファイル一覧:${NC}"
        ls -la
    fi
    
    # Pythonの簡易HTTPサーバーを使用（ポート5502でバックグラウンド実行）
    # Pythonのバージョンをチェック
    PYTHON_VERSION=$(python3 -c 'import sys; print(sys.version_info.major)' 2>/dev/null)
    
    if [ "$PYTHON_VERSION" -eq 3 ]; then
        # Python 3の場合
        (python3 -m http.server 5502 &) 2>/dev/null
    else
        # Python 2の場合（念のため）
        (python -m SimpleHTTPServer 5502 &) 2>/dev/null
    fi
    
    # サーバーが起動するまで少し待機
    sleep 2
    
    # Chromeでプロジェクトページを開く（ルートからの相対パスを使用）
    echo -e "${BLUE}ブラウザでページを開きます: http://127.0.0.1:5502/${PROJECT_PAGE}${NC}"
    open -a "Google Chrome" "http://127.0.0.1:5502/${PROJECT_PAGE}"
    
    # リファレンスURLがあれば開く
    if [ ! -z "$REFERENCE_URL" ]; then
        echo -e "${BLUE}リファレンスURLを開きます...${NC}"
        open -a "Google Chrome" "$REFERENCE_URL"
    fi
    
    # コマンドファイルがあれば実行
    if [ ! -z "$COMMAND_FILE" ] && [ -f "$COMMAND_FILE" ]; then
        echo -e "${BLUE}コマンドファイルを実行します...${NC}"
        bash "$COMMAND_FILE"
    fi
    
    # 6. プロジェクトはすでにCursorで開いている
    
    # 7. 設定変更のインタラクティブモード
    echo -e "${YELLOW}設定を変更するには、以下のキーを入力してください:${NC}"
    echo -e "1: プロジェクトルートディレクトリ"
    echo -e "2: 開きたいページ"
    echo -e "3: 開きたいURL"
    echo -e "4: 叩きたいコマンドファイル"
    echo -e "q: 終了"
    
    while true; do
        read -n 1 setting_key
        echo ""
        
        if [[ $setting_key == "q" ]]; then
            echo -e "${GREEN}終了します${NC}"
            break
        fi
        
        update_setting $setting_key
    done
}

# スクリプト実行
main
