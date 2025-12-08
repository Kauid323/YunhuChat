import yh_user_sdk as sdk

client = sdk.set_token("YOUR_TOKEN")

# 上传语音+发送语音
with open("测试.flac", "rb") as f:
    # PS: 名称可不写,默认按照文件MD5,写了名称的话获取的key应该和名称一样
    # file_bytes = f.read() 如果你没指定文件名的话请使用这个,然后把下面的 f 换成 file_bytes
    key = client.tool.upload("audio", f, name = "测试.flac").get("key")
msg = {
    "content": {
        "audio": key,
        "audio_time": 176
    }
}
print(client.msg.send("big", 2, "audio", data = msg))

# 获取指定消息信息
print(client.tool.get_msg(
    "big", # 会话ID
    "group", # 会话类型
    "abcdef", # 消息ID,不写默认获取最新消息
    before = 10, # 获取指定消息ID的前N条消息,不写默认0
    after = 10)) # 获取指定消息ID的后N条消息,不写默认0