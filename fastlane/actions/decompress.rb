module Fastlane
  module Actions
    module SharedValues
      DECOMPRESS_OUTPUT_PATH = :DECOMPRESS_OUTPUT_PATH
      DECOMPRESS_EXTRACTED_FILES = :DECOMPRESS_EXTRACTED_FILES
    end

    class DecompressAction < Action
      def self.run(params)
        require 'zip'
        require 'fileutils'
        
        # 获取参数
        zip_file_path = params[:zip_file_path]
        output_directory = params[:output_directory]
        overwrite = params[:overwrite] || true
        
        UI.message("开始解压缩文件: #{zip_file_path}")
        
        # 检查zip文件是否存在
        unless File.exist?(zip_file_path)
          UI.user_error!("压缩文件不存在: #{zip_file_path}")
        end
        
        # 检查文件是否为zip格式
        unless zip_file_path.downcase.end_with?('.zip')
          UI.user_error!("文件不是zip格式: #{zip_file_path}")
        end
        
        # 如果没有指定输出目录，使用zip文件所在目录
        if output_directory.nil? || output_directory.empty?
          output_directory = File.dirname(zip_file_path)
        end
        
        # 创建输出目录（如果不存在）
        unless Dir.exist?(output_directory)
          FileUtils.mkdir_p(output_directory)
          UI.message("创建输出目录: #{output_directory}")
        end
        
        # 生成解压后的目录名（基于zip文件名）
        zip_filename = File.basename(zip_file_path, '.zip')
        extracted_dir = File.join(output_directory, zip_filename)
        
        # 如果目录已存在，则删除（默认覆盖）
        if Dir.exist?(extracted_dir)
          FileUtils.rm_rf(extracted_dir)
          UI.message("删除已存在的目录: #{extracted_dir}")
        end
        
        # 创建解压目录
        FileUtils.mkdir_p(extracted_dir)
        
        # 解压缩文件
        extracted_files = []
        begin
          Zip::File.open(zip_file_path) do |zip_file|
            zip_file.each do |entry|
              # 跳过目录条目
              next if entry.name.end_with?('/')
              
              # 计算目标文件路径
              target_path = File.join(extracted_dir, entry.name)
              
              # 创建目标文件的父目录（如果不存在）
              target_dir = File.dirname(target_path)
              FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)
              
              # 解压文件
              entry.extract(target_path)
              extracted_files << target_path
              
              UI.message("解压文件: #{entry.name}")
            end
          end
          
          UI.success("解压缩完成！")
          UI.message("解压目录: #{extracted_dir}")
          UI.message("解压文件数量: #{extracted_files.length}")
          
          # 设置共享值
          Actions.lane_context[SharedValues::DECOMPRESS_OUTPUT_PATH] = extracted_dir
          Actions.lane_context[SharedValues::DECOMPRESS_EXTRACTED_FILES] = extracted_files
          
          # 返回结果
          result = {
            output_path: extracted_dir,
            extracted_files: extracted_files,
            file_count: extracted_files.length
          }
          
          return result
          
        rescue Zip::Error => e
          UI.user_error!("解压缩失败: #{e.message}")
        rescue => e
          UI.user_error!("解压缩过程中发生错误: #{e.message}")
        end
      end
      
      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        '解压缩zip文件到指定目录'
      end

      def self.details
        '解压缩指定的zip文件到目标目录，返回解压后的文件路径和文件列表。支持覆盖已存在的目录。'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :zip_file_path,
                                       env_name: 'FL_DECOMPRESS_ZIP_FILE_PATH',
                                       description: '要解压缩的zip文件路径（必传）',
                                       optional: false,
                                       verify_block: proc do |value|
                                         unless value && !value.empty?
                                           UI.user_error!("zip_file_path 是必传参数")
                                         end
                                       end),
          FastlaneCore::ConfigItem.new(key: :output_directory,
                                       env_name: 'FL_DECOMPRESS_OUTPUT_DIRECTORY',
                                       description: '解压输出目录（可选，默认使用zip文件所在目录）',
                                       optional: true,
                                       default_value: nil),
          FastlaneCore::ConfigItem.new(key: :overwrite,
                                       env_name: 'FL_DECOMPRESS_OVERWRITE',
                                       description: '是否覆盖已存在的目录（默认true）',
                                       optional: true,
                                       default_value: true,
                                       is_string: false)
        ]
      end

      def self.output
        [
          ['DECOMPRESS_OUTPUT_PATH', '解压后的目录路径'],
          ['DECOMPRESS_EXTRACTED_FILES', '解压后的文件列表']
        ]
      end

      def self.return_value
        '包含解压结果的哈希表，包括output_path、extracted_files和file_count'
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
