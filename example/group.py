import yh_user_sdk as sdk
# from yh_user_sdk.core.group import group
# 如果你想要单独导入group的话请使用上面这个,会导致下列命令请求格式变化 传入token的话直接group("token")就行

# 设置token, timeout参数可不写
client = sdk.set_token("你的token", timeout = 114514)

# 获取群聊信息
print(client.group.info("big"))

# 编辑群聊信息
# 你要改啥这里就写啥,按需填写,如只需要修改群聊名称的话只填写name即可
edit_group = {
    "name": "测试名称", # 群名称
    "introduction": "测试简介", # 群聊简介
    "avatar_url": "https://example.com/image", # 群聊头像url
    "direct_join": 1, # 进群免审核,1为开启
    "history_msg": 1, # 历史消息,1为开启
    "category_name": "测试分类名", # 分类名
    "category_id": 114514, # 分类ID
    "private": 1 # 是否私有,1为私有
}
print(client.group.edit_group( # 别名edit
    "big", # 群聊ID
    data = edit_group))

# 列出群成员
print(client.group.list_member(
    "big", # 群聊ID
    size = 50, # 分页大小,不写默认50
    page = 1)) # 页数,不写默认1

# 邀请加入群聊
print(client.group.invite(
    "big", # 群聊ID
    "7356666", # 被邀请者ID
    "user")) # 被邀请者类型

# 禁言用户
print(client.group.gag_member(
    "big", # 群聊ID
    "11451419180", # 要禁言的用户ID
    time = 0)) # 禁言时间,不写默认为0(-1永久禁言,0解除禁言)

# 踢出用户
print(client.group.remove_member(
    "big", # 群聊ID
    "7058262")) # 要踢出用户的ID

# 获取群房间列表
print(client.group.live_room("big")) # 群聊ID

# 群指令列表
print(client.group.instruction_list("big")) # 群聊ID

# 列出群聊中的机器人
print(client.group.bot_list("big"))

# 标签相关
# 获取标签列表
print(client.group.tag.list(
    "big", # 群聊ID
    size = 20, # 分页大小,不写默认20
    page = 1, # 分页,不写默认第一页
    search = "")) # 搜索

# 创建标签
# 提示: 字典里面内容可以不全写,有默认值
tag = {
    "tag": "标签名称", # 标签名称
    "color": "#2196F3", # 标签颜色(#FFFFFF)
    "desc": "", # 标签描述
    "sort": 0 # 排序
}
print(client.group.tag.create(
    "big", # 群聊ID
    data = tag))

# 编辑标签
# 提示: 需要改啥就写啥,其他部分不会修改
edit_tag = {
    "tag": "标签名称", # 标签名称
    "color": "#2196F3", # 标签颜色(#FFFFFF)
    "desc": "", # 标签描述
    "sort": 0 # 排序
}
print(client.group.tag.edit(
    "big", # 群聊ID
    data = edit_tag))

# 关联标签
print(client.group.tag.relate(
    "7058262", # 要关联到用户的ID
    1145)) # 标签ID

# 获取标签关联的用户
print(yt.group.tag.member(
    "big", # 群组ID
    1145, # 标签ID
    size = 50, # 分页大小
    page = 1)) # 分页(第N页)

# 取消关联标签
print(client.group.tag.relate_cancel( # 别名unrelate
    "7058262", # 取消关联的用户的ID
    1145)) # 标签ID

# 删除用户标签
print(client.group.tag.delete(1145)) # 标签ID