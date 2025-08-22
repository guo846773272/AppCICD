# 飞书机器人通知 - 快速开始指南

## 🚀 5分钟快速配置

### 第一步：创建飞书机器人

1. 在飞书中创建一个群组
2. 点击群组右上角的设置图标
3. 选择"群组设置" → "机器人" → "添加机器人"
4. 选择"自定义机器人"
5. 设置机器人名称和头像
6. 复制生成的webhook URL

### 第二步：更新配置文件

编辑 `fastlane/FastlaneConfig.json`，将你的webhook URL替换占位符：

```json
{
    "feishu_robot_webhook": "https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_ACTUAL_WEBHOOK_ID"
}
```

### 第三步：测试配置

运行测试脚本验证配置：

```bash
ruby fastlane/test_feishu.rb
```

如果看到 "✅ 测试成功！消息已发送到飞书机器人"，说明配置正确。

### 第四步：在构建流程中使用

飞书通知已经自动集成到构建流程中。当你运行：

```bash
fastlane archive
```

构建完成后会自动发送飞书通知。

## 📱 消息预览

配置完成后，你将收到类似这样的通知：

```
iOS项目构建通知

项目名称: crm-ios
当前分支: main
最近提交: 修复登录bug (张三)
构建配置: Debug
导出方式: development
下载地址: 点击下载
```

## 🔧 自定义配置

### 修改通知内容

在 `fastlane/Fastfile` 中修改 `feishu_robot_notification` 调用：

```ruby
feishu_robot_notification(
  project_name: "我的应用",          # 项目名称（可选）
  configuration: "Release",           # 构建配置
  export_method: "ad-hoc",           # 导出方式
  package_download_url: "https://..." # 下载地址
)
```

### 手动发送通知

```bash
# 基本测试
fastlane test_feishu_notification

# 自定义参数
fastlane test_feishu_notification configuration:Release export_method:ad-hoc
```

## ❗ 常见问题

**Q: 测试失败，提示webhook URL无效**
A: 检查URL格式是否正确，确保机器人仍在群组中

**Q: 消息发送成功但群组中看不到**
A: 检查机器人是否有发送消息权限，确认群组设置

**Q: 如何修改通知消息格式？**
A: 编辑 `fastlane/actions/feishu_robot_notification.rb` 中的 `build_rich_text_message` 方法

## 📚 更多信息

- 详细文档：`fastlane/FEISHU_NOTIFICATION_README.md`
- 飞书官方文档：https://open.feishu.cn/document/client-docs/bot-v3/add-custom-bot
- 问题反馈：检查fastlane日志输出

## 🎯 下一步

1. 配置webhook URL
2. 运行测试脚本
3. 集成到你的构建流程
4. 自定义通知内容（可选）

现在开始享受自动化的飞书通知吧！ 🎉
