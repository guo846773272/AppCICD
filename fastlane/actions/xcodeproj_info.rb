module Fastlane
  module Actions
    module SharedValues
      XCODEPROJ_WORKSPACE_PATH = :XCODEPROJ_WORKSPACE_PATH
      XCODEPROJ_PROJECT_PATH = :XCODEPROJ_PROJECT_PATH
      XCODEPROJ_SCHEMES = :XCODEPROJ_SCHEMES
      XCODEPROJ_DEFAULT_SCHEME = :XCODEPROJ_DEFAULT_SCHEME
      XCODEPROJ_CONFIGURATIONS = :XCODEPROJ_CONFIGURATIONS
      XCODEPROJ_TARGETS = :XCODEPROJ_TARGETS
      XCODEPROJ_BUNDLE_IDENTIFIER = :XCODEPROJ_BUNDLE_IDENTIFIER
      XCODEPROJ_VERSION = :XCODEPROJ_VERSION
      XCODEPROJ_BUILD_NUMBER = :XCODEPROJ_BUILD_NUMBER
      XCODEPROJ_DISPLAY_NAME = :XCODEPROJ_DISPLAY_NAME
    end

    class XcodeprojInfoAction < Action
      def self.run(params)
        require 'xcodeproj'
        
        # 获取项目路径，默认为当前目录
        project_path = params[:project_path] || Dir.pwd
        
        # 查找 .xcworkspace 文件
        workspace_path = find_workspace(project_path)
        project_file_path = find_project_file(project_path)
        
        if workspace_path.nil? && project_file_path.nil?
          UI.user_error!("No .xcworkspace or .xcodeproj file found in #{project_path}")
        end
        
        # 优先使用 workspace，如果没有则使用 project
        if workspace_path
          UI.message("Found workspace: #{workspace_path}")
          project_file_path = extract_project_from_workspace(workspace_path)
        end
        
        # 打开项目文件
        project = Xcodeproj::Project.open(project_file_path)
        
        # 获取 schemes
        schemes = get_schemes(project, workspace_path)
        default_scheme = schemes.first
        
        # 如果还是没有找到 schemes，尝试从项目名称推断
        if schemes.empty?
          project_name = File.basename(project_file_path, ".xcodeproj")
          schemes = [project_name]
          default_scheme = project_name
          UI.message("No schemes found, using project name: #{project_name}")
        end
        
        # 获取配置信息
        configurations = project.build_configurations.map(&:name)
        
        # 获取 targets
        targets = project.targets.map(&:name)
        
        # 获取主 target 的 bundle identifier 和版本信息
        main_target = project.targets.find { |t| t.product_type == "com.apple.product-type.application" }
        bundle_identifier = nil
        version = nil
        build_number = nil
        display_name = nil
        
        if main_target
          build_config = main_target.build_configurations.first
          if build_config
            bundle_identifier = build_config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"]
            version = build_config.build_settings["MARKETING_VERSION"]
            build_number = build_config.build_settings["CURRENT_PROJECT_VERSION"]
            display_name = build_config.build_settings["INFOPLIST_KEY_CFBundleDisplayName"]
          end
        end
        
        # 设置共享值
        Actions.lane_context[SharedValues::XCODEPROJ_WORKSPACE_PATH] = workspace_path
        Actions.lane_context[SharedValues::XCODEPROJ_PROJECT_PATH] = project_file_path
        Actions.lane_context[SharedValues::XCODEPROJ_SCHEMES] = schemes
        Actions.lane_context[SharedValues::XCODEPROJ_DEFAULT_SCHEME] = default_scheme
        Actions.lane_context[SharedValues::XCODEPROJ_CONFIGURATIONS] = configurations
        Actions.lane_context[SharedValues::XCODEPROJ_TARGETS] = targets
        Actions.lane_context[SharedValues::XCODEPROJ_BUNDLE_IDENTIFIER] = bundle_identifier
        Actions.lane_context[SharedValues::XCODEPROJ_VERSION] = version
        Actions.lane_context[SharedValues::XCODEPROJ_BUILD_NUMBER] = build_number
        Actions.lane_context[SharedValues::XCODEPROJ_DISPLAY_NAME] = display_name
        
        # 返回结果
        result = {
          workspace_path: workspace_path,
          project_path: project_file_path,
          schemes: schemes,
          default_scheme: default_scheme,
          configurations: configurations,
          targets: targets,
          bundle_identifier: bundle_identifier,
          version: version,
          build_number: build_number,
          display_name: display_name
        }
        
        UI.success("Successfully extracted Xcode project information:")
        UI.message("Workspace: #{workspace_path || 'Not found'}")
        UI.message("Project: #{project_file_path}")
        UI.message("Schemes: #{schemes.join(', ')}")
        UI.message("Default Scheme: #{default_scheme}")
        UI.message("Configurations: #{configurations.join(', ')}")
        UI.message("Targets: #{targets.join(', ')}")
        UI.message("Bundle ID: #{bundle_identifier || 'Not found'}")
        UI.message("Version: #{version || 'Not found'}")
        UI.message("Build Number: #{build_number || 'Not found'}")
        UI.message("Display Name: #{display_name || 'Not found'}")
        
        return result
      end
      
      private
      
      def self.find_workspace(project_path)
        Dir.glob(File.join(project_path, "*.xcworkspace")).first
      end
      
      def self.find_project_file(project_path)
        Dir.glob(File.join(project_path, "*.xcodeproj")).first
      end
      
      def self.extract_project_from_workspace(workspace_path)
        # 从 workspace 中提取项目文件路径
        workspace_dir = File.dirname(workspace_path)
        workspace_name = File.basename(workspace_path, ".xcworkspace")
        project_path = File.join(workspace_dir, "#{workspace_name}.xcodeproj")
        
        if File.exist?(project_path)
          return project_path
        else
          # 如果同名项目文件不存在，尝试查找其他项目文件
          project_files = Dir.glob(File.join(workspace_dir, "*.xcodeproj"))
          return project_files.first if project_files.any?
        end
        
        nil
      end
      
      def self.get_schemes(project, workspace_path)
        schemes = []
        
        # 尝试从项目文件获取 schemes
        begin
          schemes = project.schemes.map(&:name)
        rescue => e
          UI.message("Could not get schemes from project: #{e.message}")
        end
        
        # 如果项目中没有 schemes，尝试从 workspace 获取
        if schemes.empty? && workspace_path
          begin
            workspace = Xcodeproj::Workspace.new_from_xcworkspace(workspace_path)
            schemes = workspace.schemes
          rescue => e
            UI.message("Could not get schemes from workspace: #{e.message}")
          end
        end
        
        # 如果还是没有，尝试从文件系统查找
        if schemes.empty?
          schemes = find_schemes_in_filesystem(workspace_path || File.dirname(project.path))
        end
        
        # 确保 schemes 是数组
        schemes = [] if schemes.nil?
        schemes = schemes.is_a?(Array) ? schemes : []
        
        schemes
      end
      
      def self.find_schemes_in_filesystem(path)
        schemes = []
        
        # 查找共享的 schemes
        shared_schemes_path = File.join(path, "**/xcshareddata/xcschemes/*.xcscheme")
        Dir.glob(shared_schemes_path).each do |scheme_file|
          scheme_name = File.basename(scheme_file, ".xcscheme")
          schemes << scheme_name unless schemes.include?(scheme_name)
        end
        
        # 如果没有找到共享的 schemes，尝试查找用户特定的 schemes
        if schemes.empty?
          user_schemes_path = File.join(path, "**/xcuserdata/*/xcschemes/*.xcscheme")
          Dir.glob(user_schemes_path).each do |scheme_file|
            scheme_name = File.basename(scheme_file, ".xcscheme")
            # 过滤掉 Pods 相关的 schemes
            unless scheme_name.start_with?("Pods-") || schemes.include?(scheme_name)
              schemes << scheme_name
            end
          end
        end
        
        schemes
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Extract Xcode project information including workspace, scheme, and other project details'
      end

      def self.details
        'This action uses the xcodeproj gem to dynamically extract information from your Xcode project, including workspace path, available schemes, configurations, targets, and more. This is useful for automating build processes without hardcoding project-specific values.'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :project_path,
                                       env_name: 'FL_XCODEPROJ_INFO_PROJECT_PATH',
                                       description: 'Path to the directory containing your Xcode project',
                                       optional: true,
                                       default_value: Dir.pwd,
                                       verify_block: proc do |value|
                                         unless Dir.exist?(value)
                                           UI.user_error!("Project path '#{value}' does not exist")
                                         end
                                       end)
        ]
      end

      def self.output
        [
          ['XCODEPROJ_WORKSPACE_PATH', 'Path to the .xcworkspace file if found'],
          ['XCODEPROJ_PROJECT_PATH', 'Path to the .xcodeproj file'],
          ['XCODEPROJ_SCHEMES', 'Array of available scheme names'],
          ['XCODEPROJ_DEFAULT_SCHEME', 'Name of the first available scheme'],
          ['XCODEPROJ_CONFIGURATIONS', 'Array of available build configuration names'],
          ['XCODEPROJ_TARGETS', 'Array of available target names'],
          ['XCODEPROJ_BUNDLE_IDENTIFIER', 'Bundle identifier from the main target'],
          ['XCODEPROJ_VERSION', 'Marketing version from the main target'],
          ['XCODEPROJ_BUILD_NUMBER', 'Current project version from the main target'],
          ['XCODEPROJ_DISPLAY_NAME', 'Display name from the main target']
        ]
      end

      def self.return_value
        'Hash containing all the extracted project information'
      end

      def self.authors
        ['Your GitHub/Twitter Name']
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
