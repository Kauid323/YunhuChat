import httpx
import logging
from .. import config
from google.protobuf import json_format

def request_api(url, headers = None , data = None, json = False): # 后面这个json是表明返回是不是json内容
    if isinstance(data,bytes): # 判断是不是二进制数据
        response = httpx.post("https://chat-go.jwzhd.com/v1/"+url,headers = headers,data = data)
    else:
        response = httpx.post("https://chat-go.jwzhd.com/v1/"+url,headers = headers,json = data)
    response.raise_for_status()
    if not json:
        return response.content
    else:
        return response.json()

def mapping_chat_type(chat_type):
    if chat_type in config.chat_type_mapping:
        chat_type = config.chat_type_mapping[chat_type]
    return chat_type

class conversation: # 对话列表
    from ..proto import conversation_pb2

    def __init__(self, token):
        self.token = token
    
    def dismiss_notification(self, chat_id: str):
        headers = {"token": self.token}
        payload = {"chatId": chat_id}
        response = request_api("conversation/dismiss-notification", headers, data = payload, json = True)
        return response
    
    def list(self):
        headers = {"token": self.token}
        response = request_api("conversation/list", headers)
        list = self.conversation_pb2.list()
        list.ParseFromString(response)
        list = json_format.MessageToDict(list)
        return list

class misc:
    def __init__(self, token = ""): # 初始化
        self.token = token

    def request_api(self, url, headers = None):
        headers = {"token": self.token} if headers is None else headers
        transport = httpx.HTTPTransport(retries = 3)
        with httpx.Client(transport = transport, base_url = "https://chat-go.jwzhd.com/v1/misc/") as client:
            response = client.get(url, headers = headers)
            response.raise_for_status()
            return response.json()
    
    def configure_distribution(self):
        response = self.request_api("configure-distribution")
        return response
    
    def qiniu_token(self, type: str):
        type2url = { # 转 URL 的字典
            "image": "qiniu-token",
            "audio": "qiniu-token-audio",
            "file": "qiniu-token2",
            "video": "qiniu-token-video",
            "group_disk": "qiniu-token-group-disk"
        }
        url = type2url.get(type)
        if not url:
            logging.error(f"输入的 {type} 无效")
            return
        response = self.request_api(url)
        return response

    def setting(self):
        response = self.request_api("setting")
        return response

    def gray_status(self): # 没用的东西+1
        response = self.request_api("gray-status", headers = {"token": "114514"})
        return response

class disk:
    def __init__(self, token = ""):
        self.token = token
        # 别名
        self.file_list = self.list

    def request_api(self, url, headers = None, data = None):
        headers = {"token": self.token} if headers is None else headers
        with httpx.Client(base_url = "https://chat-go.jwzhd.com/v1/disk/", transport = httpx.HTTPTransport(retries = 3)) as client:
            response = client.post(url, headers = headers, json = data)
            return response.json()

    def list(self, chat_id: str, chat_type, folder_id = 0, sort = "name_asc"):
        """列出文件/文件夹"""
        chat_type = mapping_chat_type(chat_type)
        payload = {
            "chatId": chat_id,
            "chatType": int(chat_type),
            "folderId": folder_id,
            "sort": sort
        }
        response = self.request_api("file-list", data = payload)
        return response

    def create_folder(self, chat_id: str, chat_type, folder_name: str, parent_folder_id = 0):
        """创建文件夹"""
        chat_type = mapping_chat_type(chat_type)
        payload = {
            "chatId": chat_id,
            "chatType": int(chat_type),
            "folderName": folder_name,
            "parentFolderId": parent_folder_id
        }
        response = self.request_api("create-folder", data = payload)
        return response

    def upload(self, 
               chat_id: str,
               chat_type,
               data: dict):
        """上传文件"""
        chat_type = mapping_chat_type(chat_type)
        payload = {
            "chatId": chat_id,
            "chatType": int(chat_type),
            "fileSize": 0,
            "fileName": "测试文件",
            "fileMd5": "123456",
            "fileEtag": "123456",
            "qiniuKey": "disk/123456",
            "folderId": 0
        }
        payload.update(data)
        response = self.request_api("upload-file", data = payload)
        return response
    
    def rename(self, id: int, chat_type, name: str):
        """更改文件/文件夹名"""
        chat_type = mapping_chat_type(chat_type)
        payload = {
            "id": id,
            "objectType": int(chat_type),
            "name": name
        }
        response = self.request_api("rename", data = payload)
        return response

    def remove(self, id: int, chat_type):
        """移除文件(夹)"""
        chat_type = mapping_chat_type(chat_type)
        payload = {
            "id": id,
            "objectType": int(chat_type)
        }
        response = self.request_api("remove", data = payload)
        return response

class sticker:
    """表情包相关"""
    import json
    def __init__(self, token):
        self.token = token
        # 别名
        self.remove_sticker_pack = self.remove
        self.rm = self.remove

    def request_api(self, url, headers = None, data = None):
        """方便请求用的"""
        headers = {"token": self.token} if headers is None else headers
        with httpx.Client(base_url = "https://chat-go.jwzhd.com/v1/sticker/", transport = httpx.HTTPTransport(retries = 3)) as client:
            response = client.post(url, headers = headers, json = data)
        response.raise_for_status()
        return response.json()

    def list(self):
        """列出收藏表情包"""
        response = self.request_api("list")
        return response

    def detail(self, id: int):
        """列出指定的表情包信息"""
        data = {"id": int(id)}
        response = self.request_api("detail", data = data)
        return response

    def add(self, id: int):
        """添加表情包"""
        data = {"id": int(id)}
        response = self.request_api("add", data = data)
        return response

    def remove(self, id: int):
        """移除表情包"""
        return self.request_api("remove-sticker-pack", data = {"id": int(id)})

    def sort(self, data: list):
        """排序"""
        if isinstance(data, list):
            data = json.dumps(data)
        payload = {sort: data}
        response = self.request_api("sort", data = payload)
        return response

class expression:
    """个人表情收藏"""
    def __init__(self, token):
        self.token = token
        # 别名
        self.topping = self.top

    def request_api(self, url, headers = None, data = None):
        """发请求用的"""
        headers = {"token": self.token} if headers is None else headers
        with httpx.Client(base_url = "https://chat-go.jwzhd.com/v1/expression/", transport = httpx.HTTPTransport(retries = 3)) as client:
            response = client.post(url, headers = headers, json = data)
        response.raise_for_status()
        return response.json()

    def list(self):
        """列出个人收藏表情"""
        return self.request_api("list")

    def create(self, url: str):
        """创建个人收藏表情"""
        payload = {"url": url}
        return self.request_api("create", data = payload)

    def add(self, id: int):
        """添加表情"""
        payload = {"id": int(id)}
        return self.request_api("add", data = payload)

    def delete(self, id: int):
        """删除表情"""
        payload = {"id": int(id)}
        return self.request_api("delete", data = payload)

    def top(self, id: int):
        """置顶表情"""
        payload = {"id": int(id)}
        return self.request_api("topping", data = payload)

class sticky:
    """置顶会话相关"""
    def __init__(self, token):
        self.token = token
        # 别名
        self.topping = self.top
    
    def request_api(self, url, headers = None, data = None):
        """发请求用的awa"""
        headers = {"token": self.token} if headers is None else headers
        with httpx.Client(base_url = "https://chat-go.jwzhd.com/v1/sticky/", transport = httpx.HTTPTransport(retries = 3)) as client:
            response = client.post(url, headers = headers, json = data)
        response.raise_for_status()
        return response.json()

    def list(self):
        """列出置顶会话"""
        return self.request_api("list")

    def add(self, chat_id: str, chat_type):
        """添加置顶会话"""
        chat_type = mapping_chat_type(chat_type)
        payload = {
            "chatId": chat_id,
            "chatType": int(chat_type)
        }
        return self.request_api("add", data = payload)

    def delete(self, chat_id: str, chat_type):
        """移除置顶会话"""
        chat_type = mapping_chat_type(chat_type)
        payload = {
            "chatId": chat_id,
            "chatType": int(chat_type)
        }
        return self.request_api("delete", data = payload)

    def top(self, id: int):
        """将一个置顶会话移到最前"""
        payload = {"id": int(id)}
        return self.request_api("topping", data = payload)