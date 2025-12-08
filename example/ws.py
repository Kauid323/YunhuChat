import yh_user_sdk as sdk
import asyncio

async def main():
    client = sdk.set_token("Your Token")
    client_ws = client.ws.connect(
        decode = True, # 默认开启解码消息,若为False则会返回原始二进制数据
        mode = "black", # 默认黑名单模式,白名单的话是white
        list = ["heartbeat_ack"]) # 名单,里面填写推送ws消息类型
        # 如果你需要自定义设备id,在线平台请看后面教程
    async for msg in client_ws:
        print(msg)

asyncio.run(main())

# 教程2

from yh_user_sdk.core.ws import ws

async def main():
    client_ws = ws(config.token,
                    platform = "android", #在线平台,不写默认windows
                    deviceId = "114154", # 设备id,不写随机生成
                    user_id = "114154") # 用户id,不写自动获取
    async for msg in client_ws.connect():
            print(msg)

asyncio.run(main())

# decode 反序列化工具

async def main():
    client = sdk.set_token("Your Token")
    client_ws = client.ws.connect(
        decode = False) # 这边关掉让其直接返回原始数据
    async for msg in client_ws:
        msg = client.ws.decode(msg, mode = "black", list = ["heartbeat_ack"]) # 后两个解释同第一个, decode 遇到被过滤掉的消息返回的为 None
        print(msg)

asyncio.run(main())