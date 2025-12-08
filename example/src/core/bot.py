import httpx
from google.protobuf import json_format
from ..proto import bot_pb2
import logging

def request_api(url, headers = None , data = None, json = False, msg_name = None): # 后面这个json是表明返回是不是json内容,msg_name则是protobuf消息名
    with httpx.Client(base_url = "https://chat-go.jwzhd.com/v1/bot/", transport = httpx.HTTPTransport(retries = 3)) as client:
        if isinstance(data,bytes): # 判断是不是二进制数据
            response = client.post(url,headers = headers,data = data, timeout = 10)
        else:
            response = client.post(url,headers = headers,json = data, timeout = 10)
    response.raise_for_status()
    if json:
        return response.json()
    elif msg_name:
        try:
            proto_class = getattr(bot_pb2, msg_name)
            proto_instance = proto_class()
            proto_instance.ParseFromString(response.content)
            return json_format.MessageToDict(proto_instance)
        except AttributeError:
            logging.error(f"protobuf中找不到名为'{msg_name}'的message.")
            return
    else:
        return response.content

def mapping_chat_type(chat_type):
    from .. import config
    if chat_type in config.chat_type_mapping:
        chat_type = config.chat_type_mapping[chat_type]
    return chat_type

class bot:
    def __init__(self,token = ""):
        self.token = token
        # 别名
        self.bot_info = self.info
        self.bot_detail = self.detail
        self.web_edit_bot = self.edit

    def info(self, bot_id: str):
        request = bot_pb2.bot_info_send()
        request.id = bot_id
        payload = request.SerializeToString()
        response = request_api("bot-info", headers = {"token": self.token}, data =payload, msg_name = "bot_info")
        return response

    def detail(self, bot_id: str):
        payload = {"id": bot_id}
        response = request_api("bot-detail", data = payload, headers = {"token": self.token}, json = True)
        return response

    def bot_group_list(self):
        response = request_api("bot-group-list", json = True)
        return response

    def edit(self, bot_id: str, data: dict):
        bot_rsp = self.info(bot_id)
        if bot_rsp.get("code") != 1:
            logging.error(f"获取机器人信息失败, msg: {bot_rsp.get("msg")}")
            return
        bot_info = bot_rsp["data"]["bot"]
        bot_info.update(data)
        response = self.request_api("web-edit-bot", data = data)
        return response
    
    def board(self, chat_id: str, chat_type):
        request = bot_pb2.board_send()
        chat_type = mapping_chat_type(chat_type)
        request.chat_id = chat_id
        request.chat_type = int(chat_type)
        payload = request.SerializeToString()
        response = request_api("board", headers = {"token": self.token}, data = payload, msg_name = "board")
        return response