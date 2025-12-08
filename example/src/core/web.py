import httpx

class web:
    """chat-web-go 相关的请求"""
    def __init__(self, token = None):
        self.token = token
        self.user = self.user(token)
        self.group = self.group()
        self.bot = self.bot()

    class user:
        """user路由下的请求"""
        def __init__(self, token):
            self.token = token
        
        def request_api_get(self, url, headers = None):
            with httpx.Client(transport = httpx.HTTPTransport(retries = 3)) as client:
                response = client.get(f"https://chat-web-go.jwzhd.com/v1/user/{url}", headers = headers)
                response.raise_for_status()
            return response.json()

        def info(self):
            headers = {"token": self.token}
            response = self.request_api_get("info", headers = headers)
            return response

        def get(self, user_id: str):
            response = self.request_api_get(f"homepage?userId={user_id}")
            return response

    class group:
        """group路由下的"""
        def __init__(self):
            # 别名
            self.group_info = self.info

        def info(self, group_id: str):
            """获取群聊信息"""
            payload = {"groupId": group_id}
            with httpx.Client(transport = httpx.HTTPTransport(retries = 3)) as client:
                response = client.post("https://chat-web-go.jwzhd.com/v1/group/group-info", json = payload)
            return response.json()
    
    class bot:
        """bot路由下的"""
        def __init__(self):
            self.bot_info = self.info
        
        def info(self, bot_id: str):
            """获取机器人信息"""
            payload = {"botId": bot_id}
            with httpx.Client(transport = httpx.HTTPTransport(retries = 3)) as client:
                response = client.post("https://chat-web-go.jwzhd.com/v1/bot/bot-info", json = payload)
            return response.json()