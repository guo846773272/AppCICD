module Fastlane
  module Actions
    module SharedValues
      PROJECT_CONFIG_PGY_API_KEY = :PROJECT_CONFIG_PGY_API_KEY
      PROJECT_CONFIG_ALL_VALUES = :PROJECT_CONFIG_ALL_VALUES
    end

    class ProjectConfigInfoAction < Action
      def self.run(params)
        require 'json'
        
        # 获取配置文件路径，默认为 fastlane 目录下的 FastlaneConfig.json
        config_path = params[:config_path] || File.join(FastlaneCore::FastlaneFolder.path, "FastlaneConfig.json")
        
        # 检查配置文件是否存在
        unless File.exist?(config_path)
          UI.user_error!("FastlaneConfig.json not found at path: #{config_path}")
        end
        
        begin
          # 读取并解析 JSON 文件
          config_content = File.read(config_path)
          config_data = JSON.parse(config_content)
          
          # 将 string 键转换为 symbol 键
          config_data_symbols = {}
          config_data.each do |key, value|
            config_data_symbols[key.to_sym] = value
          end
          
          UI.success("Successfully loaded FastlaneConfig.json from: #{config_path}")
          
          # 设置共享值
          Actions.lane_context[SharedValues::PROJECT_CONFIG_PGY_API_KEY] = config_data_symbols[:PGY_API_KEY]
          Actions.lane_context[SharedValues::PROJECT_CONFIG_ALL_VALUES] = config_data_symbols
          
          # 输出配置信息
          UI.message("Configuration loaded:")
          config_data.each do |key, value|
            # 对于敏感信息（如 API Key），只显示部分内容
            if key.include?("API_KEY") || key.include?("SECRET") || key.include?("TOKEN")
              masked_value = value.to_s.length > 8 ? "#{value.to_s[0..3]}...#{value.to_s[-4..-1]}" : "***"
              UI.message("  #{key}: #{masked_value}")
            else
              UI.message("  #{key}: #{value}")
            end
          end
          
          return config_data_symbols
          
        rescue JSON::ParserError => e
          UI.user_error!("Failed to parse FastlaneConfig.json: #{e.message}")
        rescue => e
          UI.user_error!("Failed to read FastlaneConfig.json: #{e.message}")
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Parse and load configuration from FastlaneConfig.json file'
      end

      def self.details
        'This action reads and parses the FastlaneConfig.json file, making configuration values available as shared values throughout your fastlane lanes. It automatically masks sensitive information like API keys when displaying values.'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :config_path,
                                       env_name: 'FL_PROJECT_CONFIG_INFO_CONFIG_PATH',
                                       description: 'Path to the FastlaneConfig.json file',
                                       optional: true,
                                       default_value: nil,
                                       verify_block: proc do |value|
                                         if value && !File.exist?(value)
                                           UI.user_error!("Config file not found at path: #{value}")
                                         end
                                       end)
        ]
      end

      def self.output
        [
          ['PROJECT_CONFIG_PGY_API_KEY', 'PGY API Key from the configuration file'],
          ['PROJECT_CONFIG_ALL_VALUES', 'All configuration values as a hash']
        ]
      end

      def self.return_value
        'Hash containing all the configuration values from FastlaneConfig.json'
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
