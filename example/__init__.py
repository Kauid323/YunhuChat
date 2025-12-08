# __init__.py
from .core import user # 自动获得所有延迟加载模块
from .core import other
from .core import msg
from .core import group

class set_token:
    def __init__(self, token = None, timeout = None):
        self.token = token
        self.timeout = timeout
    
    @property
    def user(self):
        from .core.user import user  # 延迟加载
        return user(self.token)
    
    @property 
    def msg(self):
        from .core.msg import msg
        return msg(self.token, timeout = self.timeout)
    
    @property 
    def group(self):
        from .core.group import group
        return group(self.token, timeout = self.timeout)
    
    @property 
    def conversation(self):
        from .core.other import conversation
        return conversation(self.token)
    
    @property 
    def ws(self):
        from .core.ws import ws
        return ws(self.token)
    
    @property 
    def misc(self):
        from .core.other import misc
        return misc(self.token)
    
    @property 
    def tool(self):
        from .core.tool import tool
        return tool(self.token)

    @property 
    def web(self):
        from .core.web import web
        return web(self.token)

    @property 
    def disk(self):
        from .core.other import disk
        return disk(self.token)

    @property 
    def bot(self):
        from .core.bot import bot
        return bot(self.token)

    @property 
    def sticker(self):
        from .core.other import sticker
        return sticker(self.token)

    @property 
    def expression(self):
        from .core.other import expression
        return expression(self.token)

    @property 
    def sticky(self):
        from .core.other import sticky
        return sticky(self.token)