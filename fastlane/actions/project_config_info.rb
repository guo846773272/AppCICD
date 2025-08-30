module Fastlane
  module Actions
    module SharedValues
      PROJECT_CONFIG_PGY_API_KEY = :PROJECT_CONFIG_PGY_API_KEY
      PROJECT_CONFIG_ALL_VALUES = :PROJECT_CONFIG_ALL_VALUES
      PROJECT_CONFIG_SCHEME_CONFIG = :PROJECT_CONFIG_SCHEME_CONFIG
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
          
          # 递归将 string 键转换为 symbol 键
          config_data_symbols = convert_keys_to_symbols(config_data)
          
          UI.success("Successfully loaded FastlaneConfig.json from: #{config_path}")
          
          # 设置共享值
          Actions.lane_context[SharedValues::PROJECT_CONFIG_PGY_API_KEY] = config_data_symbols[:PGY_API_KEY]
          Actions.lane_context[SharedValues::PROJECT_CONFIG_ALL_VALUES] = config_data_symbols
          
          # 输出配置信息
          UI.message("Configuration loaded:")
          print_config_info(config_data_symbols)
          
          # 输出可用的scheme列表
          print_available_schemes(config_data_symbols)
          
          return config_data_symbols
          
        rescue JSON::ParserError => e
          UI.user_error!("Failed to parse FastlaneConfig.json: #{e.message}")
        rescue => e
          UI.user_error!("Failed to read FastlaneConfig.json: #{e.message}")
        end
      end
      
      private
      
      # 递归将哈希表中的string键转换为symbol键
      def self.convert_keys_to_symbols(obj)
        case obj
        when Hash
          result = {}
          obj.each do |key, value|
            result[key.to_sym] = convert_keys_to_symbols(value)
          end
          result
        when Array
          obj.map { |item| convert_keys_to_symbols(item) }
        else
          obj
        end
      end
      
      # 打印配置信息，处理嵌套结构
      def self.print_config_info(config_data, prefix = "")
        config_data.each do |key, value|
          if value.is_a?(Hash)
            UI.message("#{prefix}#{key}:")
            print_config_info(value, prefix + "  ")
          else
            # 对于敏感信息（如 API Key），只显示部分内容
            if key.to_s.include?("API_KEY") || key.to_s.include?("SECRET") || key.to_s.include?("TOKEN") || key.to_s.include?("appkey")
              masked_value = value.to_s.length > 8 ? "#{value.to_s[0..3]}...#{value.to_s[-4..-1]}" : "***"
              UI.message("#{prefix}  #{key}: #{masked_value}")
            else
              UI.message("#{prefix}  #{key}: #{value}")
            end
          end
        end
      end
      
      # 打印可用的scheme列表
      def self.print_available_schemes(config_data)
        schemes = []
        config_data.each do |key, value|
          if value.is_a?(Hash) && ![:PGY_API_KEY, :key_id, :issuer_id, :username, :team_id, :team_name, :feishu_robot_webhook_url].include?(key)
            schemes << key.to_s
          end
        end
        
        if schemes.any?
          UI.message("Available schemes: #{schemes.join(', ')}")
        end
      end
      
      # 获取特定scheme的配置
      def self.get_scheme_config(config_data, scheme_name)
        scheme_sym = scheme_name.to_sym
        if config_data[scheme_sym]
          Actions.lane_context[SharedValues::PROJECT_CONFIG_SCHEME_CONFIG] = config_data[scheme_sym]
          return config_data[scheme_sym]
        else
          UI.user_error!("Scheme '#{scheme_name}' not found in configuration. Available schemes: #{config_data.keys.select { |k| k.is_a?(Symbol) && ![:PGY_API_KEY, :key_id, :issuer_id, :username, :team_id, :team_name, :feishu_robot_webhook_url].include?(k) }.map(&:to_s).join(', ')}")
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Parse and load configuration from FastlaneConfig.json file with nested structure support'
      end

      def self.details
        'This action reads and parses the FastlaneConfig.json file, making configuration values available as shared values throughout your fastlane lanes. It supports nested configuration structures and automatically masks sensitive information like API keys when displaying values. It also provides convenient methods to access scheme-specific configurations.'
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
                                       end),
          FastlaneCore::ConfigItem.new(key: :scheme,
                                       env_name: 'FL_PROJECT_CONFIG_INFO_SCHEME',
                                       description: 'Specific scheme to extract configuration for',
                                       optional: true,
                                       default_value: nil)
        ]
      end

      def self.output
        [
          ['PROJECT_CONFIG_PGY_API_KEY', 'PGY API Key from the configuration file'],
          ['PROJECT_CONFIG_ALL_VALUES', 'All configuration values as a hash with nested structure support'],
          ['PROJECT_CONFIG_SCHEME_CONFIG', 'Configuration for a specific scheme']
        ]
      end

      def self.return_value
        'Hash containing all the configuration values from FastlaneConfig.json with nested structure support'
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
