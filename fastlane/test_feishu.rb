#!/usr/bin/env ruby

# 测试飞书机器人通知功能
# 使用方法: ruby fastlane/test_feishu.rb

require 'json'
require 'net/http'
require 'uri'

def test_feishu_notification
  # 读取配置文件
  config_path = File.join(__dir__, "FastlaneConfig.json")
  
  unless File.exist?(config_path)
    puts "错误: 找不到配置文件 #{config_path}"
    return
  end
  
  begin
    config_content = File.read(config_path)
    config_data = JSON.parse(config_content)
    feishu_robot_webhook_url = config_data["feishu_robot_webhook_url"]
    
    if feishu_robot_webhook_url.nil? || feishu_robot_webhook_url.empty? || feishu_robot_webhook_url == "YOUR_FEISHU_ROBOT_WEBHOOK_URL_HERE"
      puts "错误: 请在 FastlaneConfig.json 中配置有效的飞书机器人webhook URL"
      puts "格式: https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_WEBHOOK_ID"
      return
    end
    
    puts "配置信息:"
    puts "  Webhook URL: #{feishu_robot_webhook_url}"
    puts ""
    
    # 获取项目信息
    project_name = Dir.pwd.split('/').last
    current_branch = `git rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
    current_branch = current_branch.empty? ? "未知分支" : current_branch
    last_commit_message = `git log -1 --pretty=format:"%s (%an)" 2>/dev/null`.strip
    last_commit_message = last_commit_message.empty? ? "无提交信息" : last_commit_message
    
    puts "项目信息:"
    puts "  项目名称: #{project_name}"
    puts "  当前分支: #{current_branch}"
    puts "  最近提交: #{last_commit_message}"
    puts ""
    
    # 构建测试消息
    test_message = {
      "msg_type" => "post",
      "content" => {
        "post" => {
          "zh_cn" => {
            "title" => "飞书机器人通知测试",
            "content" => [
              [
                {
                  "tag" => "text",
                  "text" => "项目名称: "
                },
                {
                  "tag" => "text",
                  "text" => project_name
                }
              ],
              [
                {
                  "tag" => "text",
                  "text" => "当前分支: "
                },
                {
                  "tag" => "text",
                  "text" => current_branch
                }
              ],
              [
                {
                  "tag" => "text",
                  "text" => "最近提交: "
                },
                {
                  "tag" => "text",
                  "text" => last_commit_message
                }
              ],
              [
                {
                  "tag" => "text",
                  "text" => "测试时间: "
                },
                {
                  "tag" => "text",
                  "text" => Time.now.strftime("%Y-%m-%d %H:%M:%S")
                }
              ]
            ]
          }
        }
      }
    }
    
    puts "准备发送测试消息..."
    puts "消息内容: #{JSON.pretty_generate(test_message)}"
    puts ""
    
    # 发送消息
    puts "正在发送消息到飞书机器人..."
    result = send_feishu_message(feishu_robot_webhook_url, test_message)
    
    if result[:success]
      puts "✅ 测试成功！消息已发送到飞书机器人"
    else
      puts "❌ 测试失败: #{result[:message]}"
    end
    
  rescue JSON::ParserError => e
    puts "错误: 配置文件格式错误 - #{e.message}"
  rescue => e
    puts "错误: #{e.message}"
  end
end

def send_feishu_message(feishu_robot_webhook_url, message)
  uri = URI(feishu_robot_webhook_url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 10
  http.read_timeout = 10
  
  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = message.to_json
  
  response = http.request(request)
  
  if response.code == '200'
    result = JSON.parse(response.body)
    if result['code'] == 0
      return { success: true, message: "消息发送成功" }
    else
      return { success: false, message: "飞书API返回错误: #{result['msg']}" }
    end
  else
    return { success: false, message: "HTTP请求失败: #{response.code} - #{response.body}" }
  end
rescue => e
  return { success: false, message: "发送消息时发生错误: #{e.message}" }
end

if __FILE__ == $0
  puts "=== 飞书机器人通知功能测试 ==="
  puts ""
  test_feishu_notification
  puts ""
  puts "测试完成！"
end
