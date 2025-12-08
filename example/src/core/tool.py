import httpx
import logging

class tool:
    def __init__(self, token = None):
        self.token = token

    def upload(self, type, file: bytes, name = None):
        """
        上传文件,部分代码参考了114514个三连的脚本
        """
        from .other import misc
        import hashlib
        try:
            type2bucket_name = {
                "file": "chat68-file",
                "image": "chat68",
                "audio": "chat68-audio",
                "video": "chat68",
                "group_disk": "chat68-file"
            }
            client = misc(self.token)
            utoken = client.qiniu_token(type).get("data", {}).get("token")
            if not utoken:
                logging.error("获取 utoken 失败")
                return
            uhost = httpx.get(f"https://api.qiniu.com/v4/query?ak={utoken.split(':')[0]}&bucket={type2bucket_name.get(type,'chat68-file')}").json()["hosts"][0]["up"]["domains"][0]
            # 三连两行解决战斗,可读性去世.
            if not name:
                md5 = hashlib.md5(file)
                name = md5.hexdigest()
            params = {
                "token": (None, utoken),
                "key": (None, name),
                "file": (name, file)
            }
            response = httpx.post("https://"+uhost, files=params)
            return response.json()
        except Exception as e:
            logging.error(f"发生错误 {e}")

    def get_msg(self, chat_id: str, chat_type, msg_id = "", before = 0, after = 0) -> list:
        from .msg import msg
        """获取指定消息"""
        try:
            client = msg(self.token)
            msg_data = []
            if msg_id:
                response = client.list_by_mid_seq(chat_id, chat_type, msg_id = msg_id, msg_seq = -1, msg_count = 1 if not after else after)
                if response.get("status", {}).get("code") != 1:
                    logging.error(f"请求失败, msg: {response.get("status", {}).get("msg")}")
                    return
                elif not response.get("msg"):
                    logging.error(f"无法获取消息数据, rsp: {response}")
                    return
                if after:
                    msg_data = response["msg"]
                else:
                    msg_data = [response["msg"][-1]]
            if before:
                response_before = client.list(chat_id, chat_type,msg_id = msg_id, msg_count = before)
                if response_before.get("status", {}).get("code") != 1:
                    logging.error(f"请求失败, msg: {response_before.get("status", {}).get("msg")}")
                    return
                elif not response_before.get("msg"):
                    logging.error(f"无法获取消息数据, rsp: {response_before}")
                    return
                msg_data += response_before["msg"]
            return msg_data
        except Exception as e:
            logging.error(f"发生错误 {e}")