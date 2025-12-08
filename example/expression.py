import yh_user_sdk as sdk
# from yh_user_sdk.core.expression import expression

# 设置token
client = sdk.set_token("YOUR_TOKEN")

# 列出收藏表情
print(client.expression.list())

# 创建表情
print(client.expression.create("图片URL")) # 注: 似乎只能写云湖图床的,其他的会直接报错

# 添加表情
print(client.expression.add(1145)) # 表情ID

# 删除表情
print(client.expression.delete(1145)) # 表情ID

# 置顶表情 别名topping
print(client.expression.top(1145)) # 表情ID