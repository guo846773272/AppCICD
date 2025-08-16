#!/bin/bash

# 设置默认值
DEFAULT_CONFIG="Debug"
DEFAULT_EXPORT_METHOD="development"

# 显示帮助信息
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -c, --configuration CONFIG    Build configuration (Debug/Release) [default: $DEFAULT_CONFIG]"
    echo "  -e, --export-method METHOD    Export method (development/ad-hoc/enterprise/app-store) [default: $DEFAULT_EXPORT_METHOD]"
    echo "  -h, --help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # 使用默认值"
    echo "  $0 -c Release                         # 指定 Release 配置"
    echo "  $0 -e ad-hoc                          # 指定 ad-hoc 导出方式"
    echo "  $0 -c Release -e ad-hoc               # 同时指定配置和导出方式"
    echo "  $0 --configuration Release --export-method app-store"
    echo ""
}

# 解析命令行参数
CONFIGURATION=$DEFAULT_CONFIG
EXPORT_METHOD=$DEFAULT_EXPORT_METHOD

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--configuration)
            CONFIGURATION="$2"
            shift 2
            ;;
        -e|--export-method)
            EXPORT_METHOD="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# 验证参数
case $CONFIGURATION in
    Debug|Release)
        ;;
    *)
        echo "Error: Invalid configuration '$CONFIGURATION'. Must be 'Debug' or 'Release'"
        exit 1
        ;;
esac

case $EXPORT_METHOD in
    development|ad-hoc|enterprise|app-store)
        ;;
    *)
        echo "Error: Invalid export method '$EXPORT_METHOD'. Must be 'development', 'ad-hoc', 'enterprise', or 'app-store'"
        exit 1
        ;;
esac

echo "Starting archive with:"
echo "  Configuration: $CONFIGURATION"
echo "  Export method: $EXPORT_METHOD"
echo ""

# 执行 fastlane archive
bundle exec fastlane archive configuration:$CONFIGURATION export_method:$EXPORT_METHOD

# 检查执行结果
if [ $? -eq 0 ]; then
    echo "✅ Archive completed successfully!"
else
    echo "❌ Archive failed!"
    exit 1
fi
