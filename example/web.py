import yh_user_sdk as sdk
# from yh_user_sdk.core.web import web

# 先设置token(其实可以设置空,部分需要鉴权的api会无法使用)

client = sdk.set_token("YOUR TOKEN")

# user路由部分
# 获取用户自身信息(需要有效的token)
print(client.web.user.info())

# 获取其他用户信息
print(client.web.user.get("5197892")) # 示例: 获取用户 5197892 的信息

# group路由部分
# 获取群聊信息
print(client.web.group.info("635409929"))

# bot路由部分
# 获取机器人信息
print(client.web.bot.info("65450527"))