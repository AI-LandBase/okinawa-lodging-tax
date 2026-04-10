# VPS 初期セットアップ手順書

VPS を新規に構築する際の初期セットアップ手順です。devuser の作成から SSH 設定、Docker 実行環境の準備までを行います。

---

## 前提条件

- VPS の root パスワードまたは SSH 鍵でのログインが可能であること
- ローカルマシンに SSH 鍵ペア（ed25519 推奨）が作成済みであること
- VPS に Docker がインストール済みであること

---

## 手順

### 1. root で VPS に SSH ログイン

```bash
ssh root@<VPS_IP>
```

### 2. devuser の作成

```bash
adduser devuser
```

対話形式でパスワード等を設定します。

### 3. sudo・docker グループへの追加

```bash
usermod -aG sudo,docker devuser
```

### 4. SSH 公開鍵の配置

root の公開鍵を devuser にコピーします。

```bash
mkdir -p /home/devuser/.ssh
cat /root/.ssh/authorized_keys >> /home/devuser/.ssh/authorized_keys
chmod 700 /home/devuser/.ssh
chmod 600 /home/devuser/.ssh/authorized_keys
chown -R devuser:devuser /home/devuser/.ssh
```

**パーミッション要件:**

| パス | パーミッション |
|------|---------------|
| `/home/devuser/.ssh/` | 700 |
| `/home/devuser/.ssh/authorized_keys` | 600 |

### 5. /srv の所有権変更

アプリケーションのデプロイ先である `/srv` を devuser が操作できるようにします。

```bash
chown -R devuser:devuser /srv
```

### 6. リバースプロキシの配置

リバースプロキシ（Caddy）は `/srv` 以下の複数プロジェクトで共有するため、プロジェクトとは独立して `/srv/reverse-proxy/` に配置します。

```bash
mkdir -p /srv/reverse-proxy
```

本リポジトリの `reverse-proxy/` ディレクトリごとコピーします。

```bash
scp -r reverse-proxy/ devuser@<VPS_IP>:/srv/reverse-proxy/
```

**Caddyfile のドメイン設定:**

配置した `Caddyfile` の `yourdomain.com` を実際のドメインに変更してください。

```bash
vi /srv/reverse-proxy/Caddyfile
```

```
example.com {
	reverse_proxy railsapp:3000
}
```

**起動:**

```bash
cd /srv/reverse-proxy/
make up
```

### 7. SSH 秘密鍵のコピー

devuser が VPS 上から外部リポジトリ等にアクセスする場合に必要です。

**ローカルマシンから実行:**

```bash
scp ~/.ssh/id_ed25519 root@<VPS_IP>:/home/devuser/.ssh/
```

**VPS 上で権限を設定:**

```bash
chmod 600 /home/devuser/.ssh/id_ed25519
chown devuser:devuser /home/devuser/.ssh/id_ed25519
```

**パーミッション要件:**

| パス | パーミッション |
|------|---------------|
| `/home/devuser/.ssh/id_ed25519` | 600 |

---

## 動作確認

### SSH ログイン確認

ローカルマシンから devuser で SSH ログインできることを確認します。

```bash
ssh devuser@<VPS_IP>
```

**期待結果:** パスワードなしでログインできる。

### /srv 書き込み確認

devuser で `/srv` にファイルを作成・削除できることを確認します。

```bash
touch /srv/test_file && rm /srv/test_file && echo "OK"
```

**期待結果:** エラーなく `OK` と表示される。

### docker 実行確認

devuser で sudo なしに Docker コマンドを実行できることを確認します。

```bash
docker ps
```

**期待結果:** sudo なしでコンテナ一覧が表示される（グループ反映のため再ログインが必要な場合あり）。

---

## (オプション) root の SSH ログイン無効化

セキュリティ強化のため、devuser でのログインを確認した後に root の SSH ログインを無効化できます。

**SSH 設定を変更:**

```bash
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
```

**SSH サービスを再起動:**

```bash
systemctl restart sshd
```

> **注意:** この手順を実行する前に、devuser で sudo が使えることを必ず確認してください。root ログインを無効化した後にアクセスできなくなるリスクがあります。
