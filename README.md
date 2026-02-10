# Terraform自動バージョンアップ環境 (Renovate)

このリポジトリは、**Renovate**を使用してTerraformとAWSプロバイダーのバージョンを自動的にアップデートする仕組みを備えています。

## 📁 ディレクトリ構造

```
terraform/
├── .github/
│   └── workflows/
│       └── terraform-validate.yml        # 検証・テストワークフロー
├── environment/
│   ├── dev/                              # 検証環境（先にアップデート）
│   │   ├── main.tf
│   │   └── versions.tf
│   └── prod/                             # 本番環境（Dev検証後）
│       ├── main.tf
│       └── versions.tf
├── modules/
│   └── s3_bucket/                        # S3バケットモジュール
│       ├── main.tf
│       └── variables.tf
└── renovate.json                         # Renovate設定ファイル
```

## 🤖 Renovateとは

[Renovate](https://github.com/renovatebot/renovate)は、依存関係を自動的に更新してPull Requestを作成するツールです。

### メリット
- ✅ 標準的なツール（保守性が高い）
- ✅ 設定ファイルのみで動作（スクリプト不要）
- ✅ GitHub Apps統合で簡単にセットアップ
- ✅ Terraform以外の依存関係も管理可能
- ✅ セキュリティアラートにも対応

## 🚀 セットアップ手順

### 1. GitHubリポジトリの準備

```bash
cd /home/ec2-user/terraform

# Gitリポジトリの初期化（まだの場合）
git init
git add .
git commit -m "feat: Add Renovate configuration for Terraform"

# GitHubにpush
git remote add origin <your-repo-url>
git push -u origin main
```

### 2. Renovate GitHub Appのインストール

1. **Renovate GitHub Appをインストール**
   - https://github.com/apps/renovate にアクセス
   - "Install" または "Configure" をクリック
   - 対象のリポジトリを選択してインストール

2. **Renovateが自動的に動作開始**
   - インストール後、Renovateが自動的に `renovate.json` を検出
   - 初回実行時に "Configure Renovate" PRが作成される
   - このPRをマージすると本格的に動作開始

### 3. 動作確認

Renovateが正常に動作すると、以下のようなPRが自動作成されます:
- `Update Terraform (Dev) to v1.x.x`
- `Update AWS Provider (Dev) to v5.x.x`
- `Update Terraform lock files`

## ⚙️ Renovate設定の詳細

### 自動アップデートの仕組み

`renovate.json`の設定により以下の動作をします:

1. **実行スケジュール**: 毎週月曜日 10時前（日本時間）
2. **Dev環境を優先**: Dev → Prod の順でPRを作成
3. **グループ化**: 関連する更新をまとめてPR作成
4. **自動マージ**: Dev環境のminor/patch更新は自動マージ可能

### 主要な設定項目

```json
{
  "schedule": ["before 10am on Monday"],  // 実行タイミング
  "prConcurrentLimit": 3,                 // 同時PR数の上限
  "separateMinorPatch": true,             // Minor/Patchを分離
  "automerge": true                        // Dev環境は自動マージ
}
```

### PR作成パターン

| 更新対象 | PR名 | ラベル | 優先度 |
|---------|------|--------|-------|
| Terraform (Dev) | `Update Terraform (Dev) to v1.x.x` | `terraform`, `dev-environment` | 高 |
| Terraform (Prod) | `Update Terraform (Prod) to v1.x.x` | `terraform`, `prod-environment`, `needs-careful-review` | 中 |
| AWS Provider (Dev) | `Update AWS Provider (Dev) to v5.x.x` | `aws-provider`, `dev-environment` | 高 |
| AWS Provider (Prod) | `Update AWS Provider (Prod) to v5.x.x` | `aws-provider`, `prod-environment`, `needs-careful-review` | 中 |

## 📋 バージョンアップの承認フロー

### 推奨フロー

1. **Dev環境のPRが自動作成**
   - Renovateが毎週月曜に実行
   - Dev環境向けのPRが作成される

2. **自動検証が実行**
   - GitHub Actionsで `terraform validate` が実行

3. **Dev環境でテスト**
   ```bash
   cd environment/dev
   terraform init -upgrade
   terraform plan
   # 問題なければapply（任意）
   ```

4. **Dev PRをマージ**
   - minor/patch更新は自動マージ可能
   - major更新は手動レビュー推奨

5. **Prod環境のPRが作成**
   - Dev環境のマージ後に作成される

6. **Prod PRをレビュー & マージ**
   - より慎重にレビュー
   - 必要に応じてステージング環境でテスト

## ✅ テストチェックリスト

各PRには以下のチェックリストが自動追加されます:

- [ ] バージョン変更内容とリリースノートを確認
- [ ] Dev環境で`terraform init -upgrade`を実行
- [ ] Dev環境で`terraform plan`を実行
- [ ] Breaking Changesがないことを確認
- [ ] (任意) Dev環境で実際にapply
- [ ] Dev検証後、Prodに適用

## 🔧 カスタマイズ方法

### 実行頻度の変更

`renovate.json`の`schedule`を編集:

```json
{
  "schedule": ["every weekend"]  // 週末に実行
}
```

他の例:
- `"every weekday"` - 平日毎日
- `"before 3am on Monday"` - 月曜日3時前
- `"after 10pm and before 5am"` - 夜間のみ

### バージョン制約の変更

`environment/*/versions.tf`を編集:

```hcl
terraform {
  required_version = ">= 1.13.0, < 2.0.0"  # 1.x系のみ

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # 5.x系のみ
    }
  }
}
```

### 自動マージの無効化

`renovate.json`で以下を変更:

```json
{
  "packageRules": [
    {
      "matchFileNames": ["environment/dev/**"],
      "automerge": false  // Dev環境も手動マージに変更
    }
  ]
}
```

### 特定バージョンのスキップ

```json
{
  "packageRules": [
    {
      "matchPackageNames": ["hashicorp/aws"],
      "allowedVersions": "!/5.70.0/"  // 5.70.0をスキップ
    }
  ]
}
```

## 🔍 トラブルシューティング

### Renovateが動作しない

1. **GitHub Appの確認**
   ```
   リポジトリの Settings → Integrations → Renovate が有効か確認
   ```

2. **renovate.jsonの検証**
   ```bash
   # オンラインバリデータで確認
   # https://docs.renovatebot.com/config-validation/
   ```

3. **Renovateのログ確認**
   - GitHub の Checks タブで Renovate のログを確認

### PRが作成されない

- `schedule`設定を確認（時間帯が合っているか）
- `terraform.fileMatch`が正しいか確認
- 手動実行: リポジトリの Issues → "Request Renovate to run"

### GitHub Actionsの権限エラー

リポジトリの設定:
- Settings → Actions → General → Workflow permissions
- "Read and write permissions" を選択

## 🆚 Renovate vs 自作スクリプト

| 項目 | Renovate | 自作スクリプト |
|-----|----------|---------------|
| セットアップ | GitHub App インストールのみ | ワークフロー作成が必要 |
| 保守性 | 高（標準ツール） | 低（独自実装） |
| 機能 | 豊富（多言語対応等） | 限定的 |
| カスタマイズ | JSON設定で柔軟 | コード修正が必要 |
| コスト | 無料 | 無料 |

## 📚 参考資料

- [Renovate Documentation](https://docs.renovatebot.com/)
- [Renovate Terraform Manager](https://docs.renovatebot.com/modules/manager/terraform/)
- [Configuration Options](https://docs.renovatebot.com/configuration-options/)
- [Preset Configs](https://docs.renovatebot.com/presets-config/)

## 🎯 次のステップ

1. **GitHubリポジトリを作成してpush**
2. **Renovate GitHub Appをインストール**
3. **初回PRをマージして動作確認**
4. **必要に応じて`renovate.json`をカスタマイズ**

これで完全な自動化環境が整います！
