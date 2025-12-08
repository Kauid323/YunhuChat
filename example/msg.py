import yh_user_sdk as sdk
# from yh_user_sdk.core.msg import msg
# 如果你想要单独导入msg的话请使用上面这个,会导致下列命令请求格式变化 传入token的话直接msg("token")就行
import json

client = sdk.set_token("你的token", timeout = 114514) # timeout参数可以不写
print(client.msg.list_msg( # 获取消息 也可以用别名 client.msg.list
    "big", # 对象ID
    "group", # 对象类型(支持填写英文(group/bot/user 全小写) 也可以填数字(对照参照文档)) 
    msg_count = 30, # 获取消息数量 不写默认为1
    msg_id = "abcdefg")) # 从指定消息ID开始(不包含此消息),不写为最近的消息

print(client.msg.list_msg_by_seq( # 别名 list_by_seq
    "big", # 对象ID
    "group", # 对象了类型 同上
    msg_start = 0)) # 开始的消息序列(msgSeq) 最多返回31条消息

print(client.msg.list_msg_by_mid_seq( # 别名 list_msg_by_mid_seq
    "big", # 对象ID
    "group", # 对象类型 同list_msg
    msg_id = "abcdef", # 开始的消息id,返回的消息包含此消息,不写似乎会返回群聊最前面的消息
    msg_seq = -1, # 从指定的msg_seq开始(?) 不写默认-1
    msg_count = 233)) # 获取的消息数量,不写默认为1,实际获取到的消息数要+1

# 发送消息
""" msg_type对照列表
content_type_mapping = {
    "text": 1,
    "image": 2,
    "markdown": 3,
    "md": 3,
    "file": 4,
    "form": 5,
    "post": 6,
    "sticker": 7,
    "expression": 7,
    "html": 8,
    "audio": 11,
    "call": 13
}
"""
# 提示: 请按照自己的需求填写
send_msg = {
    "content": {
        "text": "测试文本", #消息文本
        "buttons": [ # 按钮内容,不是所有类型的消息都能显示按钮的
            [
                {
                    "text": "复制",
                    "actionType": 2,
                    "value": "xxxx"
                },
                {
                    "text": "点击跳转",
                    "actionType": 1,
                    "url": "http://www.baidu.com"
                }
            ]
        ],
        "file_name": "测试",
        "file": "12345678", # 欲发送文件key/url
        "mentioned_id": ["12345","114514"], # 要@用户ID
        "form": "", # 表单消息,内容建议自己抓,太复杂不写了
        "quote_msg_text": "引用消息文本", # 引用信息文本
        "image": "abcdef", # 欲发送图片key/url
        "expression_id": "114", # 个人收藏表情ID
        "file_size": 114514, # 文件大小
        "video": "test.mp4", # 欲发送视频key/url
        "audio": "test.m4a", # 语音key/url
        "audio_time": 114154, # 语音秒数
        "sticker_item_id": 233, # 表情ID
        "sticker_pack_id": 514, # 表情包ID
        "room_name": "测试文本" # 语音房间发送显示信息的文本
    },
    "command_id": 1, # 所使用命令ID
    "quote_msg_id": "abcdef" # 引用信息ID
}
print(client.msg.send_msg( # 别名send
    "big", # 对象ID
    "group", # 对象类型
    msg_type = 1, # 可不写,不写默认为1
    msg_id = None, # 消息ID,可不写 不写默认使用uuid.uuid4().hex 随机生成一个
    data = send_msg)) # 要发送的消息内容

# 编辑消息
print(client.msg.edit_msg( # 别名edit
    "big", # 消息所属的聊天对象ID
    "group", # 聊天对象类型
    msg_id = "abcdef", # 要编辑的消息ID
    msg_type = 1, # 要编辑为的消息类型,不写默认为1
    data = send_msg)) # 编辑内容,同send_msg 注意: 如果报错无相应字段说明Proto文件中无对应字段

# 查看消息编辑记录
print(client.msg.list_msg_edit_record( # 别名edit_record
    "abcdef", # 消息ID
    size = 10, # 每页消息数,不写默认10
    page = 1)) # 获取第N页,不写默认1

# 撤回消息
print(client.msg.recall_msg( # 别名recall
    "big", # 消息所属聊天ID
    "group", # 消息所属聊天类型
    "abcdef")) # 要撤回的消息ID

# 批量撤回消息
print(client.msg.recall_msg_batch( # 别名recall_batch
    "big", # 消息所属聊天ID
    "group", # 消息所属聊天类型
    ["abcd","1234"])) # 要撤回的消息列表

# 按钮事件报告
print(client.msg.button_report(
    chat_id: str # 聊天对象
    chat_type, # 对象类型
    msg_id: str, # 消息id
    user_id: str, # 用户id
    button_value: str)) # 按钮的值