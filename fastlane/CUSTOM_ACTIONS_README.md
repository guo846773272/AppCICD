# Custom Fastlane Actions

This document describes the custom actions we've created for this project.

## xcodeproj_info

A custom action that dynamically extracts Xcode project information using the `xcodeproj` gem.

### What it extracts

- **Workspace path** - Path to the `.xcworkspace` file
- **Project path** - Path to the `.xcodeproj` file  
- **Available schemes** - List of all available build schemes
- **Default scheme** - First available scheme (can be customized)
- **Build configurations** - Debug, Release, etc.
- **Targets** - List of all targets in the project
- **Bundle identifier** - From the main application target
- **Version** - Marketing version from the main target
- **Build number** - Current project version

### Usage

```ruby
# Basic usage - automatically detects project in current directory
project_info = xcodeproj_info

# Specify custom project path
project_info = xcodeproj_info(
  project_path: "/path/to/your/project"
)

# Access the extracted information
workspace = project_info[:workspace_path]
scheme = project_info[:default_scheme]
bundle_id = project_info[:bundle_identifier]
```

### Example in Fastfile

```ruby
lane :build do
  # Get project info dynamically
  project_info = xcodeproj_info
  
  # Use the info in gym
  gym(
    workspace: project_info[:workspace_path],
    scheme: project_info[:default_scheme],
    # ... other options
  )
end
```

### Benefits

- **No more hardcoded values** - Automatically adapts to different projects
- **Portable** - Works across different development environments
- **Maintainable** - No need to update Fastfile when project structure changes
- **Comprehensive** - Gets all the information you need in one call

## project_config_info

A custom action that parses and loads configuration from FastlaneConfig.json.

### What it extracts

- **PGY API Key** and other configuration values
- **All configuration** as a hash for easy access
- **Automatically masks** sensitive information

### Usage

```ruby
# Basic usage - loads from default location
config_info = project_config_info

# Specify custom config file path
config_info = project_config_info(
  config_path: "/path/to/custom/config.json"
)

# Access configuration values using symbol keys
pgy_api_key = config_info[:PGY_API_KEY]
all_config = config_info
```

### Example in Fastfile

```ruby
lane :upload do
  # Load configuration
  config_info = project_config_info
  
  # Use configuration values
  pgy_upload(
    api_key: config_info[:PGY_API_KEY],
    # ... other options
  )
end
```

### Benefits

- **Centralized configuration** management
- **Secure handling** of sensitive data
- **Easy access** to project-specific settings
- **Environment-specific** configurations

## Installation

Make sure you have the required gems:

```bash
bundle install
```

## Usage

### Archive Lane

The `archive` lane now accepts dynamic parameters for configuration and export method:

```bash
# 基本用法（使用默认值）
bundle exec fastlane archive

# 指定配置
bundle exec fastlane archive configuration:Release

# 指定导出方式
bundle exec fastlane archive export_method:ad-hoc

# 同时指定多个参数
bundle exec fastlane archive configuration:Release export_method:ad-hoc
```

### Using the Shell Script

We've provided a convenient shell script for easier usage:

```bash
# 使用默认值
./fastlane/scripts/archive.sh

# 指定配置
./fastlane/scripts/archive.sh -c Release

# 指定导出方式
./fastlane/scripts/archive.sh -e ad-hoc

# 同时指定
./fastlane/scripts/archive.sh -c Release -e ad-hoc

# 显示帮助
./fastlane/scripts/archive.sh --help
```

### Other Lanes

Run your lanes as usual:

```bash
bundle exec fastlane archive
bundle exec fastlane pgy_upload_lane
```

Both actions will automatically detect your project structure and configuration, providing the necessary information for building and uploading.
