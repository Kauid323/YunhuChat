from google.protobuf import json_format
import httpx
from ..proto import user_pb2
import uuid

def request_api(url, headers = None , data = None, json = False): # 后面这个json是表明返回是不是json内容
    if isinstance(data,bytes): # 判断是不是二进制数据
        response = httpx.post("https://chat-go.jwzhd.com/v1/user/"+url,headers = headers,data = data)
    else:
        response = httpx.post("https://chat-go.jwzhd.com/v1/user/"+url,headers = headers,json = data)
    response.raise_for_status()
    if not json:
        return response.content
    else:
        return response.json()

class user:
    def __init__(self, token = None):
        self.token = token
        # 下面是函数别名
        self.get = self.get_user

    def info(self):
        headers = {"token": self.token}
        response = httpx.get("https://chat-go.jwzhd.com/v1/user/info",headers = headers)
        response.raise_for_status()
        user_info = user_pb2.info()
        user_info.ParseFromString(response.content)
        user_info = json_format.MessageToDict(user_info)
        return user_info
    
    def get_user(self,user_id: str):
        headers = {"token": "4a76aaaa-bbbb-cccc-0721-c9dead825555"}
        user = user_pb2.get_user_send()
        user.id = user_id
        data = user.SerializeToString()
        response = request_api("get-user", headers, data = data)
        user_info = user_pb2.get_user()
        user_info.ParseFromString(response)
        user_info = json_format.MessageToDict(user_info)
        return user_info
    
    def captcha(self):
        response = request_api("captcha", None, json = True)
        return response
    
    def verification_login(self, mobile: str, captcha: str, deviceId = uuid.uuid4().hex , platform = "windows"):
        payload = {
            "mobile": mobile,
            "captcha": captcha,
            "deviceId": deviceId,
            "platform": platform
        }
        response = request_api("verification-login",data = payload, json = True)
        return response
    
    def medal(self):
        headers = {"token": self.token}
        response = request_api("medal",headers)
        medal = user_pb2.medal()
        medal.ParseFromString(response)
        medal = json_format.MessageToDict(medal)
        return medal
    
    def edit_nickname(self, name: str):
        headers = {"token": self.token}
        data = user_pb2.edit_nickname_send()
        data.name = name
        payload = data.SerializeToString()
        response = request_api("edit-nickname",headers,data = payload)
        status = user_pb2.edit_nickname()
        status.ParseFromString(response)
        status = json_format.MessageToDict(status)
        return status
    
    def edit_avatar(self, url: str):
        headers = {"token": self.token }
        data = user_pb2.edit_avatar_send()
        data.url = url
        payload = data.SerializeToString()
        response = request_api("edit-avatar", headers, data = payload)
        status = user_pb2.edit_avatar()
        status.ParseFromString(response)
        status = json_format.MessageToDict(status)
        return status
    
    @staticmethod
    def email_login(email: str, passwd: str, deviceId = uuid.uuid4().hex, platform = "windows"):
        payload = {
            "email": email,
            "password": passwd,
            "deviceId": deviceId,
            "platform": platform
        }
        response = request_api("email-login", data = payload, json = True)
        return response
    
    def logout(self, deviceId: str):
        headers = {"token": self.token}
        payload = {"deviceId": deviceId}
        response = request_api("logout", headers, data = payload, json = True)
        return response