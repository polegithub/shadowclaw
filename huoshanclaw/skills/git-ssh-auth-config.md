# Git SSH 认证配置流程（长期解决代码提交权限问题）

## 场景
解决反复生成 Fine-grained tokens 容易过期、需要重复提供的问题，配置一次长期有效。

## 操作步骤

### 1. 生成 SSH 密钥对
```bash
# 生成 ed25519 类型的密钥（更安全、更短）
ssh-keygen -t ed25519 -C "openclaw-agent@local" -f ~/.ssh/id_ed25519 -N "" -q
```
- `-N ""` 表示不设置密码，无需每次输入
- 公钥会保存在 `~/.ssh/id_ed25519.pub`，私钥保存在 `~/.ssh/id_ed25519`

### 2. 添加 GitHub/GitLab 公钥
获取公钥内容：
```bash
cat ~/.ssh/id_ed25519.pub
```
将输出的公钥内容添加到代码托管平台的 SSH 密钥列表中：
- GitHub: Settings → SSH and GPG keys → New SSH key
- GitLab: Preferences → SSH Keys → Add new key
- Gitee: 设置 → SSH 公钥 → 添加公钥

### 3. 配置 GitHub 主机密钥（避免首次连接验证失败）
```bash
ssh-keyscan github.com >> ~/.ssh/known_hosts
```
如果是其他托管平台，把 `github.com` 换成对应域名即可。

### 4. 修改仓库远程地址为 SSH 格式
```bash
# 查看当前远程地址
git remote -v

# 替换为 SSH 格式（示例：GitHub 仓库）
git remote set-url origin git@github.com:username/repo.git
```
SSH 格式地址一般为 `git@<域名>:<用户名>/<仓库名>.git`，和 HTTPS 格式的 `https://<域名>/<用户名>/<仓库名>.git` 对应。

### 5. 测试提交
```bash
# 尝试拉取/推送代码
git fetch origin
git push origin <分支名>
```
如果没有报错提示输入密码，说明配置成功。

## 优势
- 长期有效，不会过期，无需反复生成 token
- 更安全，私钥只保存在本地，不会在网络传输中泄露
- 支持多个代码托管平台，同一个公钥可以添加到多个平台使用

## 注意事项
- 私钥文件 `~/.ssh/id_ed25519` 权限必须是 600（只读），否则 SSH 会拒绝使用
- 不要泄露私钥内容，公钥可以公开
- 如果需要更换机器，只需要把密钥对复制到新机器的 `~/.ssh/` 目录下即可继续使用
