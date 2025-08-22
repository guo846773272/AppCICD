# 飞书机器人通知功能使用说明

## 概述

`feishu_robot_notification` action 用于在iOS项目构建完成后，通过飞书机器人发送富文本通知消息，包含项目构建的详细信息。

## 功能特性

- 自动获取项目名称、当前Git分支、最近提交信息
- 支持自定义构建配置（Debug/Release）
- 支持自定义导出方式（development/ad-hoc/app-store）
- 支持添加包下载地址链接
- 使用飞书富文本消息格式，支持超链接

## 配置要求

### 1. 飞书机器人设置

1. 在飞书中创建一个群组
2. 添加自定义机器人
3. 获取webhook URL
4. 在 `fastlane/FastlaneConfig.json` 中配置webhook地址

### 2. 配置文件更新

在 `fastlane/FastlaneConfig.json` 中添加：

```json
{
    "feishu_robot_webhook_url": "https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_WEBHOOK_ID"
}
```

## 使用方法

### 基本用法

```ruby
feishu_robot_notification(
  configuration: "Release",
  export_method: "ad-hoc",
  package_download_url: "https://example.com/app.ipa"
)
```

### 参数说明

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `project_name` | String | 否 | 自动获取 | 项目名称（优先使用INFOPLIST_KEY_CFBundleDisplayName） |
| `feishu_robot_webhook_url` | String | 否 | 从配置文件读取 | 飞书机器人webhook URL |
| `configuration` | String | 否 | "Debug" | 构建配置 |
| `export_method` | String | 否 | "development" | 导出方式 |
| `package_download_url` | String | 否 | "" | 包下载地址 |

### 在Fastlane Lane中使用

#### 1. 自动集成到构建流程

在 `pgy_query_upload_status` lane中已经自动集成了飞书通知功能，当蒲公英上传完成后会自动发送通知。

#### 2. 手动调用

```ruby
lane :custom_notification do
  feishu_robot_notification(
    project_name: "我的应用",  # 可选，如果不提供将自动获取
    configuration: "Release",
    export_method: "app-store",
    package_download_url: "https://example.com/app.ipa"
  )
end
```

#### 3. 测试通知功能

```bash
# 测试飞书机器人通知
fastlane test_feishu_notification

# 带参数测试
fastlane test_feishu_notification configuration:Release export_method:ad-hoc package_download_url:https://example.com/test.ipa
```

## 消息格式

发送的飞书消息包含以下信息：

1. **项目名称**: 优先使用INFOPLIST_KEY_CFBundleDisplayName，如果没有则使用scheme名称
2. **当前分支**: 自动获取Git当前分支
3. **最近提交**: 自动获取最近一次Git提交信息
4. **构建配置**: 用户指定的Debug/Release
5. **导出方式**: 用户指定的development/ad-hoc/app-store
6. **下载地址**: 可点击的下载链接（如果提供）

## 消息示例

```
iOS项目构建通知

项目名称: crm-ios
当前分支: main
最近提交: 修复登录bug (张三)
构建配置: Release
导出方式: ad-hoc
下载地址: 点击下载
```

## 错误处理

- 如果webhook URL未配置，会显示错误信息
- 如果网络请求失败，会显示HTTP错误信息
- 如果飞书API返回错误，会显示API错误信息

## 注意事项

1. 确保飞书机器人有发送消息的权限
2. webhook URL需要保密，不要提交到公开代码库
3. 消息发送频率建议控制在合理范围内，避免被飞书限制
4. 支持iOS、macOS和Android平台

## 故障排除

### 常见问题

1. **webhook URL无效**
   - 检查URL是否正确
   - 确认机器人是否仍在群组中

2. **消息发送失败**
   - 检查网络连接
   - 确认飞书服务状态

3. **权限不足**
   - 确认机器人有发送消息权限
   - 检查群组设置

### 调试方法

使用测试lane来验证配置：

```bash
fastlane test_feishu_notification
```

查看fastlane日志输出，确认各个步骤是否正常执行。
