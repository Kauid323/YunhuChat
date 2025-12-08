import yh_user_sdk as sdk
# from yh_user_sdk.core.other import sticker

# 设置token
client = sdk.set_token("YOUR_TOKEN")

# 列出收藏的表情包
print(client.sticker.list())

# 获取表情包详情
print(client.sticker.detail(1145)) # 表情包ID

# 添加表情包
print(client.sticker.add(1145)) # 表情包ID

# 删除表情包, 别名remove_sticker_pack, rm
print(client.sticker.remove(1145)) # 表情包ID

# 对表情包进行排序
data = [
    {
        "id": "1145", # 表情包ID
        "sort": "2" # 排序,数字越大越靠前
    },
    {
        "id": "19180",
        "sort": "1"
    },
    # More
    # ...
]
print(client.stick.sort(data))