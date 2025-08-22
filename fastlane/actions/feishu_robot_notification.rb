module Fastlane
  module Actions
    module SharedValues
      FEISHU_ROBOT_NOTIFICATION_RESULT = :FEISHU_ROBOT_NOTIFICATION_RESULT
    end

    class FeishuRobotNotificationAction < Action
      def self.run(params)
        require 'json'
        require 'net/http'
        require 'uri'
        
        # 获取飞书机器人webhook URL（必传参数）
        feishu_robot_webhook_url = params[:feishu_robot_webhook_url]
        if feishu_robot_webhook_url.nil? || feishu_robot_webhook_url.empty?
          UI.user_error!("feishu_robot_webhook_url is required parameter. Please provide it.")
        end
        
        # 获取项目信息（只获取传入的参数，不自动获取）
        display_name = params[:display_name]
        current_branch_or_tag = params[:current_branch_or_tag]
        last_commit_message = params[:last_commit_message]
        last_commit_hash = params[:last_commit_hash]
        configuration = params[:configuration] || "Debug"
        export_method = params[:export_method] || "development"
        package_download_url = params[:package_download_url] || ""
        
        # 构建富文本消息
        message = build_rich_text_message(
          display_name: display_name,
          current_branch_or_tag: current_branch_or_tag,
          last_commit_message: last_commit_message,
          last_commit_hash: last_commit_hash,
          configuration: configuration,
          export_method: export_method,
          package_download_url: package_download_url
        )
        
        # 发送消息
        result = send_feishu_message(feishu_robot_webhook_url, message)
        
        # 设置共享值
        Actions.lane_context[SharedValues::FEISHU_ROBOT_NOTIFICATION_RESULT] = result
        
        UI.success("飞书机器人通知发送成功！")
        return result
      end
      
      private
      
      def self.build_rich_text_message(params)
        content = []
        
        # 只添加传入的参数对应的信息
        if params[:display_name]
          content << [
            {
              "tag" => "text",
              "text" => "Display Name: "
            },
            {
              "tag" => "text",
              "text" => params[:display_name]
            }
          ]
        end
        
        if params[:current_branch_or_tag]
          content << [
            {
              "tag" => "text",
              "text" => "branch or tag: "
            },
            {
              "tag" => "text",
              "text" => params[:current_branch_or_tag]
            }
          ]
        end
        
        if params[:last_commit_message]
          content << [
            {
              "tag" => "text",
              "text" => "commit message: "
            },
            {
              "tag" => "text",
              "text" => params[:last_commit_message]
            }
          ]
        end
        
        if params[:last_commit_hash]
          content << [
            {
              "tag" => "text",
              "text" => "commit hash: "
            },
            {
              "tag" => "text",
              "text" => params[:last_commit_hash]
            }
          ]
        end
        
        # 构建基础消息结构
        message = {
          "msg_type" => "post",
          "content" => {
            "post" => {
              "zh_cn" => {
                "title" => "iOS项目构建通知",
                "content" => content
              }
            }
          }
        }
        
        # 添加configuration信息
        message["content"]["post"]["zh_cn"]["content"] << [
          {
            "tag" => "text",
            "text" => "configuration: "
          },
          {
            "tag" => "text",
            "text" => params[:configuration]
          }
        ]
        
        # 添加export_method信息
        message["content"]["post"]["zh_cn"]["content"] << [
          {
            "tag" => "text",
            "text" => "export_method: "
          },
          {
            "tag" => "text",
            "text" => params[:export_method]
          }
        ]
        
        # 如果有下载地址，添加下载链接
        if params[:package_download_url] && !params[:package_download_url].empty?
          message["content"]["post"]["zh_cn"]["content"] << [
            {
              "tag" => "text",
              "text" => "download: "
            },
            {
              "tag" => "a",
              "text" => params[:package_download_url],
              "href" => params[:package_download_url]
            }
          ]
        end
        
        message
      end
      
      def self.send_feishu_message(feishu_robot_webhook_url, message)
        uri = URI(feishu_robot_webhook_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        
        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = 'application/json'
        request.body = message.to_json
        
        response = http.request(request)
        
        if response.code == '200'
          result = JSON.parse(response.body)
          if result['code'] == 0
            return { success: true, message: "消息发送成功" }
          else
            UI.user_error!("飞书API返回错误: #{result['msg']}")
          end
        else
          UI.user_error!("HTTP请求失败: #{response.code} - #{response.body}")
        end
      rescue => e
        UI.user_error!("发送飞书消息时发生错误: #{e.message}")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        '发送飞书机器人通知，包含项目构建信息'
      end

      def self.details
        '使用飞书机器人webhook发送富文本消息，只显示传入的参数对应的信息。feishu_robot_webhook_url为必传参数。'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :feishu_robot_webhook_url,
                                       env_name: 'FL_FEISHU_ROBOT_NOTIFICATION_FEISHU_ROBOT_WEBHOOK_URL',
                                       description: '飞书机器人webhook URL（必传）',
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :display_name,
                                       env_name: 'FL_FEISHU_ROBOT_NOTIFICATION_DISPLAY_NAME',
                                       description: '项目显示名称（可选）',
                                       optional: true,
                                       default_value: nil),
          FastlaneCore::ConfigItem.new(key: :current_branch_or_tag,
                                       env_name: 'FL_FEISHU_ROBOT_NOTIFICATION_CURRENT_BRANCH_OR_TAG',
                                       description: '分支或标签（可选）',
                                       optional: true,
                                       default_value: nil),
          FastlaneCore::ConfigItem.new(key: :last_commit_message,
                                       env_name: 'FL_FEISHU_ROBOT_NOTIFICATION_LAST_COMMIT',
                                       description: '最近一次提交信息（可选）',
                                       optional: true,
                                       default_value: nil),
          FastlaneCore::ConfigItem.new(key: :last_commit_hash,
                                       env_name: 'FL_FEISHU_ROBOT_NOTIFICATION_LAST_COMMIT_HASH',
                                       description: '最近一次提交的UUID（可选）',
                                       optional: true,
                                       default_value: nil),
          FastlaneCore::ConfigItem.new(key: :configuration,
                                       env_name: 'FL_FEISHU_ROBOT_NOTIFICATION_CONFIGURATION',
                                       description: 'configuration (Debug/Release)',
                                       optional: true,
                                       default_value: 'Debug'),
          FastlaneCore::ConfigItem.new(key: :export_method,
                                       env_name: 'FL_FEISHU_ROBOT_NOTIFICATION_EXPORT_METHOD',
                                       description: 'export_method (development/ad-hoc/app-store)',
                                       optional: true,
                                       default_value: 'development'),
          FastlaneCore::ConfigItem.new(key: :package_download_url,
                                       env_name: 'FL_FEISHU_ROBOT_NOTIFICATION_PACKAGE_DOWNLOAD_URL',
                                       description: '包下载地址',
                                       optional: true,
                                       default_value: '')
        ]
      end

      def self.output
        [
          ['FEISHU_ROBOT_NOTIFICATION_RESULT', '飞书机器人通知发送结果']
        ]
      end

      def self.return_value
        '包含发送结果的哈希表'
      end

      def self.authors
        ['Your GitHub/Twitter Name']
      end

      def self.is_supported?(platform)
        [:ios, :mac, :android].include?(platform)
      end
    end
  end
end
