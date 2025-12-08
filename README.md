# 云湖 (YunhuM3) - Flutter IM 应用

这是一个基于 Flutter 开发的云湖即时通讯应用，使用云湖官方 API。

## 功能特性

- ✅ 用户登录（邮箱密码）
- ✅ 用户信息管理
- ✅ WebSocket 实时通信
- ✅ 会话列表
- ✅ 消息收发
- ✅ 支持 Protobuf 和 JSON 混合格式
- 🚧 群组管理（开发中）
- 🚧 文件传输（开发中）

## 技术栈

- **Flutter** - 跨平台UI框架
- **Provider** - 状态管理
- **HTTP** - 网络请求
- **WebSocket** - 实时通信
- **Protobuf** - 数据序列化
- **SharedPreferences** - 本地存储

## 项目结构

```
lib/
├── config/              # 配置文件
│   └── api_config.dart  # API配置和常量
├── models/              # 数据模型
│   ├── user_model.dart
│   ├── conversation_model.dart
│   └── message_model.dart
├── services/            # 服务层
│   ├── api_service.dart        # API服务
│   ├── websocket_service.dart  # WebSocket服务
│   └── storage_service.dart    # 本地存储服务
├── providers/           # 状态管理
│   └── auth_provider.dart
├── screens/             # 页面
│   ├── login_screen.dart
│   └── home_screen.dart
├── utils/               # 工具类
│   └── protobuf_helper.dart
└── main.dart           # 入口文件
```

## 开始使用

### 环境要求

- Flutter SDK >= 3.10.3
- Dart SDK >= 3.10.3

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
# 在调试模式运行
flutter run

# 在发布模式运行
flutter run --release

# 针对特定平台
flutter run -d windows
flutter run -d android
flutter run -d ios
```

### 构建应用

```bash
# Windows
flutter build windows

# Android
flutter build apk

# iOS
flutter build ios
```

## API 说明

本应用使用云湖官方 API：

- **Base URL**: `https://chat-go.jwzhd.com`
- **WebSocket URL**: `wss://chat-ws-go.jwzhd.com/ws`

### 主要 API 端点

- `POST /v1/user/email-login` - 邮箱登录
- `GET /v1/user/info` - 获取用户信息
- `POST /v1/conversation/list` - 获取会话列表
- `POST /v1/msg/list-message` - 获取消息列表
- `POST /v1/msg/send-message` - 发送消息

## Protobuf 支持

本应用支持 Protobuf 和 JSON 混合格式：

- 部分 API 返回 JSON 格式（如登录接口）
- 部分 API 返回 Protobuf 格式（如用户信息、会话列表、消息列表）
- 应用会自动检测并解析相应格式

### Protobuf 编译（可选）

如需完整的 Protobuf 支持，需要编译 `.proto` 文件：

```bash
# 安装 protoc 编译器
# https://grpc.io/docs/protoc-installation/

# 安装 Dart protobuf 插件
dart pub global activate protoc_plugin

# 编译 proto 文件（example 文件夹中的 .proto 文件）
protoc --dart_out=lib/generated -I example example/*.proto
```

## 配置说明

### API 配置

编辑 `lib/config/api_config.dart` 修改 API 配置：

```dart
class ApiConfig {
  static const String baseUrl = 'https://chat-go.jwzhd.com';
  static const String wsUrl = 'wss://chat-ws-go.jwzhd.com/ws';
  // ...
}
```

### 聊天类型

- `1` - 用户对用户
- `2` - 群组
- `3` - 机器人

### 内容类型

- `1` - 文本
- `2` - 图片
- `3` - Markdown
- `4` - 文件
- `7` - 表情
- `11` - 语音

## 使用说明

1. **登录**
   - 使用云湖账号邮箱和密码登录
   - 登录成功后会自动连接 WebSocket

2. **查看会话**
   - 主页显示会话列表
   - 显示用户信息和在线状态

3. **发送消息**
   - 功能开发中...

## 开发指南

### 添加新功能

1. 在 `lib/models/` 创建数据模型
2. 在 `lib/services/api_service.dart` 添加 API 方法
3. 在 `lib/providers/` 创建状态管理
4. 在 `lib/screens/` 创建页面

### 调试

```bash
# 查看日志
flutter logs

# 清理构建缓存
flutter clean

# 检查依赖
flutter pub outdated
```

## 常见问题

### Q: 构建失败？
A: 运行 `flutter clean` 然后 `flutter pub get`

### Q: WebSocket 连接失败？
A: 检查网络连接和 token 是否有效

### Q: Protobuf 解析错误？
A: 部分 API 需要特殊的 Protobuf 解析，如遇问题请查看日志

## 许可证

本项目仅供学习交流使用。

## 相关链接

- [Flutter 官方文档](https://flutter.dev/docs)
- [Protobuf 官方文档](https://protobuf.dev/)
- [云湖 API 文档](./yhapi/)

## 贡献

欢迎提交 Issue 和 Pull Request！

---

Made with ❤️ using Flutter
