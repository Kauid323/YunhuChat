import yh_user_sdk as sdk
# from yh_user_sdk.core.bot import bot

client = sdk.set_token("YOUR_TOKEN")

# 获取机器人信息
print(client.bot.info("76965303")) # bot id

# 获取自己创建的所有机器人信息
print(client.bot.bot_group_list())

# 获取看板信息
print(client.bot.board(
    "big", # 对象ID
    "group")) # 对象类型