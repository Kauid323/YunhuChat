import yh_user_sdk as sdk
# from yh_user_sdk.core.user import user
# 如果你想要单独导入user的话用上面这个,后面命令都需要改 例如说第一个client应该改为 client = user("YOUR_TOKEN") 获取用户信息是 client.info()

# 建议配合用户API文档一起看
client = sdk.set_token("你的token") # token可以留空, 若token为空会导致一些需要鉴权的API无法使用
response = client.user.email_login("YOUR_EMAIL@example.com", "YOUR_PASSWD", # 邮箱密码登陆
deviceId = "114514", # 设备id可以随便写,非必须参数,不写随机生成一个
platform = "android") # 登陆平台,非必须参数,不写默认为Windows
token = response.get("data", {}).get("token") # 获取响应中的token
print(client.user.info()) # 打印用户自身信息
print(client.user.get_user("7058262")) # 打印用户ID为7058262的用户信息 你也可以用下面这个(等效)
print(client.user.get("7058262"))

print(client.user.medal()) # 打印用户自身勋章信息
print(client.user.edit_avatar("https://example.com/image_url")) # 更换用户头像 注意: 云湖部分API(如get-user)会强制替换头像url中域名为云湖图床的域名
print(client.user.edit_nickname("更换用户名测试")) # 更换用户名
print(client.user.logout("要登出的设备ID")) # 退出登陆