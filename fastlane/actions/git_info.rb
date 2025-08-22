module Fastlane
  module Actions
    module SharedValues
      GIT_INFO_CUSTOM_VALUE = :GIT_INFO_CUSTOM_VALUE
      GIT_LAST_COMMIT_MESSAGE = :GIT_LAST_COMMIT_MESSAGE
      GIT_LAST_COMMIT_HASH = :GIT_LAST_COMMIT_HASH
      GIT_CURRENT_BRANCH_OR_TAG = :GIT_CURRENT_BRANCH_OR_TAG
    end

    class GitInfoAction < Action
      def self.run(params)
        UI.message("开始获取Git信息...")
        
        # 获取最近一次提交信息
        last_commit_message = get_last_commit_message
        UI.message("最近一次提交信息: #{last_commit_message}")
        
        # 获取最近一次提交的UUID
        last_commit_hash = get_last_commit_hash
        UI.message("最近一次提交UUID: #{last_commit_hash}")
        
        # 获取当前分支或标签
        current_branch_or_tag = get_current_branch_or_tag
        UI.message("当前分支或标签: #{current_branch_or_tag}")
        
        # 设置共享值（保持向后兼容）
        Actions.lane_context[SharedValues::GIT_LAST_COMMIT_MESSAGE] = last_commit_message
        Actions.lane_context[SharedValues::GIT_LAST_COMMIT_HASH] = last_commit_hash
        Actions.lane_context[SharedValues::GIT_CURRENT_BRANCH_OR_TAG] = current_branch_or_tag
        
        # 返回结果，可以直接通过返回值访问
        result = {
          last_commit_message: last_commit_message,
          last_commit_hash: last_commit_hash,
          current_branch_or_tag: current_branch_or_tag
        }
        
        UI.success("Git信息获取成功！")
        return result
      end
      
      private
      
      def self.get_last_commit_message
        # 获取最近一次提交信息，格式：feat: 修改了xxx
        commit_message = `git log -1 --pretty=format:"%s" 2>/dev/null`.strip
        commit_message.empty? ? "无提交信息" : commit_message
      rescue
        "无提交信息"
      end
      
      def self.get_last_commit_hash
        # 获取最近一次提交的完整hash
        commit_hash = `git log -1 --pretty=format:"%H" 2>/dev/null`.strip
        commit_hash.empty? ? "无提交hash" : commit_hash
      rescue
        "无提交hash"
      end
      
      def self.get_current_branch_or_tag
        # 获取当前分支或标签
        # 先尝试获取当前分支
        branch = `git rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
        
        if branch && !branch.empty? && branch != "HEAD"
          # 如果有远程分支，获取远程分支名
          remote_branch = `git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null`.strip
          return remote_branch.empty? ? branch : remote_branch
        else
          # 如果没有分支，尝试获取标签
          tag = `git describe --tags --exact-match 2>/dev/null`.strip
          return tag.empty? ? "未知分支或标签" : tag
        end
      rescue
        "未知分支或标签"
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        '获取Git仓库的基本信息，包括最近提交信息、提交hash和当前分支/标签'
      end

      def self.details
        '获取Git仓库的以下信息：1. 最近一次提交信息（如：feat: 修改了xxx）2. 最近一次提交的UUID 3. 当前代码分支或标签。可以通过返回值直接访问，如：git_info[:last_commit_message]'
      end

      def self.available_options
        # 这个action不需要额外参数
        []
      end

      def self.output
        [
          ['GIT_LAST_COMMIT_MESSAGE', '最近一次提交信息'],
          ['GIT_LAST_COMMIT_HASH', '最近一次提交的UUID'],
          ['GIT_CURRENT_BRANCH_OR_TAG', '当前分支或标签']
        ]
      end

      def self.return_value
        '包含Git信息的哈希表，可以直接通过键值访问，如：git_info[:last_commit_message]'
      end

      def self.authors
        ['Your GitHub/Twitter Name']
      end

      def self.is_supported?(platform)
        # 支持所有平台，因为Git信息获取不依赖特定平台
        true
      end
    end
  end
end
