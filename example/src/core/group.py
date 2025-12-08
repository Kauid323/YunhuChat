import httpx
import re
from google.protobuf import json_format
from ..proto import group_pb2
import logging
from .. import config

def request_api(url, headers = None , data = None, json = False, msg_name = None): # 后面这个json是表明返回是不是json内容
    if isinstance(data,bytes): # 判断是不是二进制数据
        response = httpx.post("https://chat-go.jwzhd.com/v1/group/"+url,headers = headers,data = data, timeout = group.timeout)
    else:
        response = httpx.post("https://chat-go.jwzhd.com/v1/group/"+url,headers = headers,json = data, timeout = group.timeout)
    response.raise_for_status()
    if json:
        return response.json()
    elif msg_name:
        try:
            proto_class = getattr(group_pb2, msg_name)
            proto_instance = proto_class()
            proto_instance.ParseFromString(response.content)
            return json_format.MessageToDict(proto_instance)
        except AttributeError:
            logging.error(f"protobuf中找不到名为'{msg_name}'的message.")
            return
    else:
        return response.content

def status_only(data): # 专门负责解只有一种status的情况
    status = group_pb2.edit_group()
    status.ParseFromString(data)
    status = json_format.MessageToDict(status)
    return status

def mapping_chat_type(chat_type):
    if chat_type in config.chat_type_mapping:
        chat_type = config.chat_type_mapping[chat_type]
    return chat_type

class group:
    timeout = 10
    def __init__(self, token, timeout =  None):
        self.token = token
        self.tag = self.tag(token, timeout = timeout)
        self.timeout = timeout if timeout else self.timeout
        # 别名部分
        self.edit = self.edit_group

    def info(self, group_id: str):
        headers = {"token": self.token}
        request = group_pb2.info_send()
        request.group_id = group_id
        payload = request.SerializeToString()
        response = request_api("info", headers, data = payload,msg_name = "info")
        return response

    def list_member(self, group_id: str, size = 50, page = 1):
        headers = {"token": self.token}
        request = group_pb2.list_member_send()
        request.group_id = group_id
        request.data.size = int(size)
        request.data.page = int(page)
        payload = request.SerializeToString()
        response = request_api("list-member", headers, data = payload, msg_name = "list_member")
        return response

    def edit_group(self, group_id: str, data = {}):
        headers = {"token": self.token}
        group_info = self.info(group_id)
        if group_info.get("status", {}).get("code") != 1:
            logging.error(f"请求出错, msg: {group_info.get("status").get("msg")}")
            return group_info
        group_data = group_info["data"]
        request = group_pb2.edit_group_send()
        json_format.ParseDict(group_data, request, ignore_unknown_fields=True)
        json_format.ParseDict(data, request, ignore_unknown_fields=False)
        payload = request.SerializeToString()
        response = request_api("edit-group", headers, data = payload)
        status = status_only(response)
        return status

    def invite(self, group_id: str, chat_id: str, chat_type):
        headers = {"token": self.token}
        chat_type = mapping_chat_type(chat_type)
        payload = {
            "groupId": group_id,
            "chatId": chat_id,
            "chatType": int(chat_type)
        }
        response = request_api("invite", headers, data = payload, json = True)
        return response

    def gag_member(self, group_id: str, user_id: str, time = 0):
        headers = {"token": self.token}
        time = int(time)
        if time not in [-1,0,600,3600,21600,43200]:
            logging.warn("截止该功能发布,云湖目前禁言功能只能选择 10min, 1h, 6h, 12h 和永久这几个时间,其他时间禁言可能失败")
        payload = {
            "groupId": group_id,
            "userId": user_id,
            "gag": time
        }
        response = request_api("gag-member", headers, data = payload, json = True)
        return response

    def remove_member(self, group_id: str, user_id):
        headers = {"token": self.token}
        payload = {
            "groupId": group_id,
            "user_id": user_id
        }
        response = request_api("remove-member", headers, data = payload, json = True)
        return response

    def live_room(self, group_id: str):
        headers = {"token": self.token}
        payload = {"groupId": group_id}
        response = request_api("live-room", headers, data = payload, json = True)
        return response
    
    def instruction_list(self, group_id: str):
        headers = {"token": self.token}
        payload = {"groupId": group_id}
        response = request_api("instruction-list", headers, data = payload, json = True)
        return response

    def bot_list(self, group_id: str):
        headers = {"token": self.token}
        request = group_pb2.bot_list_send()
        request.group_id = group_id
        payload = request.SerializeToString()
        response = request_api("bot-list", headers = headers, data = payload, msg_name = "bot_list")
        return response

    class tag:
        def __init__(self, token, timeout = None):
            self.token = token
            self.timeout = timeout if timeout else 10
            # 别名
            self.unrelate = self.relate_cancel
            self.members = self.member

        def request_api(self, url, headers = None, data = None):
            if not headers:
              headers = {"token": self.token}
            response = httpx.post("https://chat-go.jwzhd.com/v1/group-tag/"+url, headers = headers, json = data, timeout = self.timeout)
            response.raise_for_status()
            return response.json()

        def check_color(self, color):
            hex_color_pattern = re.compile(r'^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$') # 用于校验是否输入了有效的颜色值
            if hex_color_pattern.match(color):
                return True
            else:
                return False

        def list(self, group_id: str, size = 20, page = 1, search = ""):
            payload = {
                "groupId": group_id,
                "size": int(size),
                "page": int(page),
                "tag": str(search)
            }
            response = self.request_api("list", data = payload)
            return response

        def create(self, group_id: str, data = {}):
            payload = {
                "groupId": group_id,
                "tag": "标签名称",
                "color": "#2196F3",
                "desc": "",
                "sort": 0
            }
            payload.update(data)
            if not self.check_color(payload["color"]):
                logging.error(f"传入的颜色值 {payload["color"]} 无效")
                return

            response = self.request_api("create", data = payload)
            return response
        
        def edit(self, group_id: str, tag_id: int, data: dict):
            tag_response = self.list(group_id, size = 1145141918)
            if tag_response.get("code") != 1:
                logging.error(f"请求出错, msg: {tag_response["msg"]}")
                return tag_response
            tag_info = next((tag for tag in tag_response['data']['list'] if tag['id'] == tag_id), None)
            if not tag_info:
                logging.error(f"找不到标签id为 {tag_id} 的标签") # PS: 云湖对于编辑不存在的标签ID报错是 "修改失败，该标签已存在"
                return
            tag_info.update(data)
            if not self.check_color(tag_info["color"]):
                logging.error(f"传入的颜色值 {tag_info["color"]} 无效")
                return
            response = self.request_api("edit", data = tag_info)
            return response

        def member(self, group_id: str, tag_id: int, size = 50, page = 1):
            request = group_pb2.tag_member_send()
            request.data.size = int(size)
            request.data.page = int(page)
            request.group_id = group_id
            request.tag_id = int(tag_id)
            payload = request.SerializeToString()
            with httpx.Client(transport = httpx.HTTPTransport(retries = 3)) as client:
                response = client.post("https://chat-go.jwzhd.com/v1/group-tag/members", headers = {"token": self.token}, data = payload)
            member = group_pb2.tag_member()
            member.ParseFromString(response.content)
            return json_format.MessageToDict(member)
     
        def relate(self, user_id: str, tag_id: int):
            payload = {
                "userId": user_id,
                "tagGroupId": tag_id
            }
            response = self.request_api("relate", data = payload)
            return response

        def relate_cancel(self, user_id: str, tag_id: int):
            payload = {
                "userId": user_id,
                "tagGroupId": tag_id
            }
            response = self.request_api("relate-cancel", data = payload)
            return response

        def delete(self, tag_id: int):
            payload = {"id": tag_id}
            response = self.request_api("delete", data = payload)
            return response