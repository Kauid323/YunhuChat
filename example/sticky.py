import yh_user_sdk as sdk
# from yh_user_sdk.core.other import sticky

# 设置token
client = sdk.set_token("YOUR_TOKEN")

# 列出置顶会话
print(client.sticky.list())

# 添加置顶会话
print(client.sticky.add(
    "big", # 会话ID
    "group")) # 会话类型

# 移除置顶会话
print(client.sticky.delete(
    "big", # 会话ID
    "group")) # 会话类型

# 把一个置顶会话移动到最前面 别名 topping
print(client.sticky.top(1145)) # 置顶会话ID(不是chatId)