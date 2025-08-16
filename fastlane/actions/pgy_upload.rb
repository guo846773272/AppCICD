module Fastlane
  module Actions
    module SharedValues
      PGY_UPLOAD_CUSTOM_VALUE = :PGY_UPLOAD_CUSTOM_VALUE
    end

    class PgyUploadAction < Action
      def self.run(params)
        puts "pgy action params:"
        p params

        _api_key = params[:_api_key]
        package_file_path = params[:package_file_path]

        UI.header("1、获取上传的 token")

        get_token_uri = "https://www.pgyer.com/apiv2/app/getCOSToken"
        get_token_command = "curl -X POST \"https://www.pgyer.com/apiv2/app/getCOSToken\" " +
                            "-d \"_api_key=#{_api_key}&buildType=#{params[:buildType]}&buildInstallType=#{params[:buildInstallType]}&buildDescription=#{params[:buildDescription]}&buildUpdateDescription=#{params[:buildUpdateDescription]}\""
        get_token_command_result = `#{get_token_command}`

        puts get_token_command
        puts get_token_command_result
        get_token_command_result_json = JSON.parse(get_token_command_result)
        data = get_token_command_result_json["data"]
        endpoint = data["endpoint"]
        key = data["key"]
        params = data["params"]
        signature = params["signature"]
        xCosSecurityToken = params["x-cos-security-token"]
        xCosMetaFileName = params["x-cos-meta-file-name"]

        UI.header("2、上传文件到第上一步获取的 URL")

        puts xCosMetaFileName
        puts endpoint
        puts package_file_path

        upload_package_command = "curl --location '#{endpoint}' \
--form 'signature=\"#{signature}\"' \
--form 'x-cos-security-token=\"#{xCosSecurityToken}\"' \
--form 'key=\"#{key}\"' \
--form 'file=@\"#{package_file_path}\"'"

        puts upload_package_command
        upload_package_command_result = `#{upload_package_command}`
        puts "upload_package_command_result"
        puts upload_package_command_result
        # upload_package_command_result_json = JSON.parse(upload_package_command_result)

        # get_build_info_command = "curl \"https://www.pgyer.com/apiv2/app/buildInfo?_api_key=#{_api_key}&buildKey=#{key}\""
        # get_build_info get_build_info_command

        @build_key = key
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
          FastlaneCore::ConfigItem.new(
            key: :platform_type,
            description: "ios/android", # a short description of this parameter
            type: String,
            default_value: "android",
            verify_block: proc do |value|
              UI.user_error!("platform_type 只能为 `ios`或者`android`") unless (value == "ios" || value == "android")
              # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
            end,
          ),
          FastlaneCore::ConfigItem.new(key: :_api_key,
                                       #  env_name: "FL_PGY_API_KEY", # The name of the environment variable
                                       description: "(必填) API Key，请见 https://www.pgyer.com/doc/view/api#auth", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error!("No API key for PgyAction given, pass using `_api_key: '_api_key'`") unless (value and not value.empty?)
                                         # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :buildType,
                                       description: "(必填) 需要上传的应用类型，如果是iOS类型请传ios或ipa，如果是Android类型请传android或apk", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error!("buildType empty") unless (value and not value.empty?)
                                         # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :buildInstallType,
                                       is_string: false,
                                       default_value: 1,
                                       description: "(选填)应用安装方式，值为(1,2,3，默认为1 公开安装)。1：公开安装，2：密码安装，3：邀请安装" # a short description of this parameter
            ),
          FastlaneCore::ConfigItem.new(key: :buildDescription,
                                       default_value: "Banggood",
                                       description: "(选填) 应用介绍，如没有介绍请传空字符串，或不传。" # a short description of this parameter
            ),
          FastlaneCore::ConfigItem.new(key: :buildUpdateDescription,
                                       #  is_string: false, # true: verifies the input is a string, false: every kind of value
                                       #  default_value: false
                                       description: "(选填) 版本更新描述，请传空字符串，或不传。" # a short description of this parameter
            ), # the default value if the user didn't provide one
          FastlaneCore::ConfigItem.new(key: :package_file_path,
                                       #  is_string: false, # true: verifies the input is a string, false: every kind of value
                                       #  default_value: false
                                       type: String,
                                       description: "(必填) App 文件的本地路径", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error!("file") unless (value and not value.empty?)
                                         # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end), # the default value if the user didn't provide one
        ]
      end

      def self.output
        # Define the shared values you are going to provide
        # Example
        [
          ["PGY_UPLOAD_CUSTOM_VALUE", "A description of what this value contains"],
        ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
        return @build_key
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
