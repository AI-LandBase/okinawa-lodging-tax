.PHONY: help
help: ## ヘルプを表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ==============================================
# 初期セットアップ用（実行後はこのセクションを削除してください）
# ==============================================

.PHONY: init
init: ## 【削除予定】Railsアプリケーションを作成（初回のみ）
	@echo "📦 Railsアプリケーションを作成します..."
	@[ -f README.md ] && cp README.md README.md.bak || true
	@[ -f .gitignore ] && cp .gitignore .gitignore.bak || true
	docker compose -f compose.development.yaml --env-file .env.development run --rm --workdir /app railsapp \
	rails new . --name okinawa_lodging_tax --database=postgresql --css=tailwind --javascript=importmap --skip-test --force
	@[ -f README.md.bak ] && mv README.md.bak README.md || true
	@if [ -f .gitignore.bak ]; then \
		cat .gitignore.bak >> .gitignore; \
		awk '!seen[$$0]++' .gitignore > .gitignore.tmp && mv .gitignore.tmp .gitignore; \
		rm -f .gitignore.bak; \
	fi
	@echo "✅ Rails アプリケーションを作成しました"
	@echo "⚙️  Procfile.devをDocker環境用に調整します..."
	@if [ -f Procfile.dev ]; then \
		if ! grep -q "\-b 0.0.0.0" Procfile.dev; then \
			perl -i -pe 's/bin\/rails server/bin\/rails server -b 0.0.0.0/' Procfile.dev; \
			echo "✅ Procfile.dev を Docker 環境用に編集しました"; \
		fi \
	fi
	@echo "📦 gemを追加します..."
	docker compose -f compose.development.yaml --env-file .env.development run --rm --workdir /app railsapp \
	bash -c "bundle add square.rb devise devise-i18n kaminari rack-cors rails-i18n paper_trail prawn combine_pdf && \
	bundle add pry-rails bullet brakeman --group development && \
	bundle add rspec-rails factory_bot_rails faker --group 'development,test'"
	@echo "✅ gemを追加しました"
	@echo "📄 Square initializerを作成します..."
	@mkdir -p config/initializers
	@printf '%s\n' \
		'require "square"' \
		'' \
		'SQUARE_CLIENT = if ENV["SQUARE_ACCESS_TOKEN"].present?' \
		'  Square::Client.new(' \
		'    token: ENV.fetch("SQUARE_ACCESS_TOKEN"),' \
		'    base_url: ENV.fetch("SQUARE_ENVIRONMENT", "sandbox") == "production" ? Square::Environment::PRODUCTION : Square::Environment::SANDBOX' \
		'  )' \
		'end' \
		'' \
		'SQUARE_LOCATION_ID = ENV["SQUARE_LOCATION_ID"]' \
		> config/initializers/square.rb
	@echo "✅ Square initializerを作成しました"
	@echo "📄 CORS initializerを作成します..."
	@printf '%s\n' \
		'# CORS configuration' \
		'# Adjust origins for your production environment' \
		'' \
		'Rails.application.config.middleware.insert_before 0, Rack::Cors do' \
		'  allow do' \
		'    origins "http://localhost:3000"' \
		'' \
		'    resource "*",' \
		'      headers: :any,' \
		'      methods: [:get, :post, :put, :patch, :delete, :options, :head]' \
		'  end' \
		'end' \
		> config/initializers/cors.rb
	@echo "✅ CORS initializerを作成しました"
	@echo "📦 .gitignoreにプロジェクト固有エントリを追加します..."
	@printf '\n# Facility-specific assets\napp/assets/images/facility/*\n!app/assets/images/facility/.gitkeep\n\n# Backups\nbackups/\n' >> .gitignore
	@echo "✅ .gitignoreを更新しました"
	@echo "🎉 セットアップ完了！ 次のコマンド: make up"

# ==============================================
# 開発用コマンド
# ==============================================

.PHONY: up
up: ## コンテナを起動
	docker compose -f compose.development.yaml --env-file .env.development up -d
	@echo "アプリケーションが起動しました: http://localhost:3000"

.PHONY: down
down: ## コンテナを停止
	docker compose -f compose.development.yaml --env-file .env.development down --remove-orphans
	@echo "✅ コンテナを停止しました"

.PHONY: bash
bash: ## railsapp コンテナに入る
	docker compose -f compose.development.yaml --env-file .env.development exec railsapp bash

.PHONY: test
test: ## RSpecテストを実行
	docker compose -f compose.development.yaml --env-file .env.development exec \
		-e DATABASE_URL=postgres://postgres-user:postgres-password@postgresdb:5432/okinawa_lodging_tax_test \
		railsapp bundle exec rspec

.PHONY: clean
clean: ## このプロジェクトのDocker関連をクリーン（公式イメージは保持）
	docker compose -f compose.development.yaml --env-file .env.development down -v --rmi local

# ==============================================
# 本番環境用コマンド
# ==============================================

.PHONY: prod-deploy
prod-deploy: ## 本番環境をデプロイ（ビルド→再作成→マイグレーション→シード）
	docker compose -f compose.production.yaml --env-file .env.production build --no-cache
	docker compose -f compose.production.yaml --env-file .env.production down
	docker compose -f compose.production.yaml --env-file .env.production up -d
	docker compose -f compose.production.yaml --env-file .env.production exec railsapp rails db:create db:migrate db:seed
	@echo "✅ デプロイが完了しました"

.PHONY: prod-logs
prod-logs: ## 本番環境のログを表示
	docker compose -f compose.production.yaml --env-file .env.production logs -f

.PHONY: prod-bash
prod-bash: ## 本番環境のrailsappコンテナに入る
	docker compose -f compose.production.yaml --env-file .env.production exec railsapp bash

.PHONY: prod-db-reset
prod-db-reset: ## 本番環境のデータベースをリセット（注意：全データ削除）
	@echo "⚠️  警告: 全てのデータが削除されます。続行しますか? [y/N]" && read ans && [ $${ans:-N} = y ]
	docker compose -f compose.production.yaml --env-file .env.production exec railsapp rails db:reset
	@echo "✅ データベースをリセットしました"

.PHONY: prod-secret
prod-secret: ## SECRET_KEY_BASEを生成して表示
	docker compose -f compose.production.yaml --env-file .env.production run --rm railsapp bundle exec rails secret

.PHONY: prod-ps
prod-ps: ## 本番環境のコンテナ状態を表示
	docker compose -f compose.production.yaml --env-file .env.production ps

# ==============================================
# バックアップ用コマンド
# ==============================================

BACKUP_DIR := backups
BACKUP_RETENTION_DAYS ?= 7
BACKUP_CRON_SCHEDULE ?= 0 2 * * *
BACKUP_POSTGRES_USER := $(shell grep '^POSTGRES_USER=' .env.production 2>/dev/null | cut -d= -f2)
BACKUP_POSTGRES_DB := $(shell grep '^POSTGRES_DB=' .env.production 2>/dev/null | cut -d= -f2)

.PHONY: prod-backup
prod-backup: ## 本番DBをバックアップ（即時実行）
	@mkdir -p $(BACKUP_DIR)
	@FILE=$(BACKUP_DIR)/$$(date +%Y%m%d_%H%M%S).sql.gz; \
	docker compose -f compose.production.yaml --env-file .env.production exec -T db pg_dump --clean --if-exists -U $(BACKUP_POSTGRES_USER) $(BACKUP_POSTGRES_DB) | gzip > $$FILE && \
	echo "✅ バックアップを作成しました: $$FILE" || { echo "❌ バックアップに失敗しました"; rm -f $$FILE; exit 1; }
	@find $(BACKUP_DIR) -name "*.sql.gz" -mtime +$(BACKUP_RETENTION_DAYS) -delete && \
	echo "🗑️  $(BACKUP_RETENTION_DAYS)日以上前のバックアップを削除しました"

.PHONY: prod-backup-list
prod-backup-list: ## バックアップ一覧をサイズ付きで表示
	@ls -lh $(BACKUP_DIR)/*.sql.gz 2>/dev/null || echo "バックアップファイルがありません"

.PHONY: prod-backup-restore
prod-backup-restore: ## 指定ファイルからDBをリストア（例: make prod-backup-restore FILE=backups/20240101_020000.sql.gz）
	@test -n "$(FILE)" || { echo "エラー: FILE=<バックアップファイルパス> を指定してください"; exit 1; }
	@test -f "$(FILE)" || { echo "エラー: ファイルが見つかりません: $(FILE)"; exit 1; }
	@echo "⚠️  警告: $(FILE) からリストアします。現在のデータが上書きされます。続行しますか? [y/N]" && read ans && [ $${ans:-N} = y ]
	@gunzip -c $(FILE) | docker compose -f compose.production.yaml --env-file .env.production exec -T db psql -U $(BACKUP_POSTGRES_USER) $(BACKUP_POSTGRES_DB)
	@echo "✅ リストアが完了しました"

.PHONY: prod-backup-cron
prod-backup-cron: ## cronにバックアップジョブを登録（デフォルト: 毎日2時）
	@CRON_CMD="$(BACKUP_CRON_SCHEDULE) cd $$(pwd) && make prod-backup >> logs/backup.log 2>&1"; \
	( crontab -l 2>/dev/null | grep -v "make prod-backup"; echo "$$CRON_CMD" ) | crontab -
	@echo "✅ cronジョブを登録しました: $(BACKUP_CRON_SCHEDULE)"

.PHONY: prod-backup-cron-remove
prod-backup-cron-remove: ## cronからバックアップジョブを削除
	@crontab -l 2>/dev/null | grep -v "make prod-backup" | crontab -
	@echo "✅ cronジョブを削除しました"

.PHONY: prod-backup-cron-status
prod-backup-cron-status: ## cronジョブの状態と最新ログを表示
	@echo "=== 登録済みcronジョブ ==="
	@crontab -l 2>/dev/null | grep "make prod-backup" || echo "バックアップcronジョブは登録されていません"
	@echo ""
	@echo "=== 最新のcronログ (直近20行) ==="
	@tail -n 20 logs/backup.log 2>/dev/null || echo "ログファイルがありません"
