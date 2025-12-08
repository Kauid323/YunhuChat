import httpx
from ..proto import msg_pb2
from google.protobuf import json_format
import uuid
import json
from .. import config

def request_api(url, headers = None , data = None, json = False): # 后面这个json是表明返回是不是json内容
    if isinstance(data,bytes): # 判断是不是二进制数据
        response = httpx.post("https://chat-go.jwzhd.com/v1/msg/"+url,headers = headers,data = data, timeout = msg.timeout)
    else:
        response = httpx.post("https://chat-go.jwzhd.com/v1/msg/"+url,headers = headers,json = data, timeout = msg.timeout)
    response.raise_for_status()
    if not json:
        return response.content
    else:
        return response.json()

def status_only(data): # 专门负责解只有一种status的情况
    status = msg_pb2.recall_msg()
    status.ParseFromString(data)
    status = json_format.MessageToDict(status)
    return status

def mapping_chat_type(chat_type):
    if chat_type in config.chat_type_mapping:
        chat_type = config.chat_type_mapping[chat_type]
    return chat_type

class msg:
    timeout = 60
    def __init__(self, token, timeout = None):
        self.token = token
        self.timeout = timeout if timeout else self.timeout
        # 下面都是别名
        self.list = self.list_msg
        self.list_by_seq = self.list_msg_by_seq
        self.list_by_mid_seq = self.list_msg_by_mid_seq
        self.send = self.send_msg
        self.recall = self.recall_msg
        self.recall_batch = self.recall_msg_batch
        self.edit = self.edit_msg
        self.edit_record = self.list_msg_edit_record

    def list_msg(self,
       chat_id: str,
       chat_type,
       msg_count = 1,
       msg_id = ""):
       headers = {"token": self.token}
       chat_type = mapping_chat_type(chat_type)
       request = msg_pb2.list_message_send()
       request.chat_id = chat_id
       request.chat_type = int(chat_type)
       request.msg_count = int(msg_count)
       request.msg_id = msg_id
       payload = request.SerializeToString()
       response = request_api("list-message", headers, data = payload)
       msg = msg_pb2.list_message()
       msg.ParseFromString(response)
       msg = json_format.MessageToDict(msg)
       return msg
    
    def list_msg_by_seq(self, chat_id: str, chat_type, msg_start = 0):
        chat_type = mapping_chat_type(chat_type)
        headers = {"token": self.token}
        request = msg_pb2.list_message_by_seq_send()
        request.chat_id = chat_id
        request.chat_type = int(chat_type)
        request.msg_seq = msg_start
        payload = request.SerializeToString()
        response = request_api("list-message-by-seq", headers ,data = payload)
        msg = msg_pb2.list_message_by_seq()
        msg.ParseFromString(response)
        msg = json_format.MessageToDict(msg)
        return msg
    
    def list_msg_by_mid_seq(self, chat_id: str, chat_type, msg_id = "", msg_count = 1, msg_seq = -1):
        chat_type = mapping_chat_type(chat_type)
        headers = {"token": self.token}
        request = msg_pb2.list_message_by_mid_seq_send()
        request.chat_id = chat_id
        request.chat_type = int(chat_type)
        request.msg_id = msg_id
        request.msg_seq = int(msg_seq)
        request.msg_count = msg_count
        payload = request.SerializeToString()
        response = request_api("list-message-by-mid-seq", headers, data = payload)
        msg = msg_pb2.list_message_by_mid_seq()
        msg.ParseFromString(response)
        msg = json_format.MessageToDict(msg)
        return msg
    
    def send_msg(self,
                  chat_id: str,
                  chat_type,
                  msg_type = 1, # ~~别问为啥不是content_type~~
                  msg_id = None,
                  data = {}):
        chat_type = mapping_chat_type(chat_type)
        if msg_type in config.content_type_mapping:
           msg_type = config.content_type_mapping[msg_type]
        headers = {"token": self.token}
        request = msg_pb2.send_message_send()
        if isinstance(data.get("content",{}).get("buttons"), list): # 论云湖把list当str发
            data["content"]["buttons"] = json.dumps(data["content"]["buttons"])
        if isinstance(data.get("content",{}).get("expression_id"), int):
            data["content"]["expression_id"] = str(data["content"]["expression_id"])
        msg = {
            "msg_id": uuid.uuid4().hex if not msg_id else msg_id,
            "chat_id": chat_id,
            "chat_type": int(chat_type),
            "content_type": int(msg_type)
        }
        msg.update(data)
        json_format.ParseDict(msg, request, ignore_unknown_fields=False)
        payload = request.SerializeToString()
        response = request_api("send-message", headers , data = payload)
        status = status_only(response)
        return status
    
    def list_msg_edit_record(self, msg_id: str, size = 10, page = 1):
        headers = {"token": self.token}
        payload = {
            "msgId": msg_id,
            "size": size,
            "page": page
        }
        response = request_api("list-message-edit-record", headers, data = payload, json = True)
        return response
    
    def recall_msg(self, chat_id: str, chat_type, msg_id: str):
        chat_type = mapping_chat_type(chat_type)
        headers = {"token": self.token}
        request = msg_pb2.recall_msg_send()
        request.chat_id = chat_id
        request.chat_type = int(chat_type)
        request.msg_id = msg_id
        payload = request.SerializeToString()
        response = request_api("recall-msg", headers, data = payload)
        status = status_only(response)
        return status
    
    def recall_msg_batch(self, chat_id: str, chat_type, msg_id: list):
        chat_type = mapping_chat_type(chat_type)
        headers = {"token": self.token}
        request = msg_pb2.recall_msg_batch_send()
        request.chat_id = chat_id
        request.chat_type = int(chat_type)
        request.msg_id.extend(msg_id)
        payload = request.SerializeToString()
        response = request_api("recall-msg-batch", headers, data = payload)
        status = status_only(response)
        return status
    
    def edit_msg(self, chat_id: str, chat_type, msg_id: str, msg_type = 1, data = {}):
        chat_type = mapping_chat_type(chat_type)
        if msg_type in config.content_type_mapping:
           msg_type = config.content_type_mapping[msg_type]
        headers = {"token": self.token}
        request = msg_pb2.edit_message_send()
        payload_dict = {
            "msg_id": msg_id,
            "chat_id": chat_id,
            "chat_type": int(chat_type),
            "content_type": int(msg_type)
        }
        payload_dict.update(data)
        json_format.ParseDict(payload_dict, request, ignore_unknown_fields=False)
        payload = request.SerializeToString()
        response = request_api("edit-message", headers, data = payload)
        status = status_only(response)
        return status
    
    def button_report(self, chat_id: str, chat_type, msg_id: str, user_id: str, button_value: str):
        chat_type = mapping_chat_type(chat_type)
        headers = {"token": self.token}
        request = msg_pb2.button_report_send()
        request.chat_id = chat_id
        request.chat_type = int(chat_type)
        request.msg_id = msg_id
        request.user_id = user_id
        request.button_value = button_value
        payload = request.SerializeToString()
        response = request_api("button-report", headers, data = payload)
        status = status_only(response)
        return status