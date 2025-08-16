module Fastlane
  module Actions
    module SharedValues
      PGY_QUERY_CUSTOM_VALUE = :PGY_QUERY_CUSTOM_VALUE
    end

    class PgyQueryAction < Action
      def self.run(params)
        _api_key = params[:_api_key]
        build_key = params[:build_key]

        UI.header("3、检测应用是否发布完成，并获取发布应用的信息")

        get_build_info_command = "curl \"https://www.pgyer.com/apiv2/app/buildInfo?_api_key=#{_api_key}&buildKey=#{build_key}\""
        puts get_build_info_command
        get_build_info_command_result = `#{get_build_info_command}`
        puts get_build_info_command_result
        get_build_info_command_result_json = JSON.parse(get_build_info_command_result)

        @get_build_info_command_result_json = get_build_info_command_result_json
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "A short description with <= 80 characters of what this action does"
      end

      def self.details
        # Optional:
        # this is your chance to provide a more detailed description of this action
        "You can use this action to do cool things..."
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :_api_key,
                                       description: "(必填) API Key，请见 鉴权说明 https://www.pgyer.com/doc/view/api#auth", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error!("No API token for PgyQueryAction given, pass using `api_token: 'token'`") unless (value and not value.empty?)
                                         # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :build_key,
                                       description: "key 上传文件存储标识唯一 key", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error!("build_key") unless (value and not value.empty?)
                                         # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :development,
                                       env_name: "FL_PGY_QUERY_DEVELOPMENT",
                                       description: "Create a development certificate instead of a distribution one",
                                       is_string: false, # true: verifies the input is a string, false: every kind of value
                                       default_value: false), # the default value if the user didn't provide one
        ]
      end

      def self.output
        # Define the shared values you are going to provide
        # Example
        [
          ["PGY_QUERY_CUSTOM_VALUE", "A description of what this value contains"],
        ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
        return @get_build_info_command_result_json
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["Your GitHub/Twitter Name"]
      end

      def self.is_supported?(platform)
        # you can do things like
        #
        #  true
        #
        #  platform == :ios
        #
        #  [:ios, :mac].include?(platform)
        #

        platform == :ios
      end
    end
  end
end
