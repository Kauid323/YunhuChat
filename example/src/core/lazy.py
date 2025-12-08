# lazy.py
import importlib
from typing import Dict, Any

class LazyLoader:
    _modules: Dict[str, Any] = {}  # 缓存已加载的模块
    
    def __init__(self, module_path: str):
        self.module_path = module_path
    
    def __getattr__(self, name):
        if self.module_path not in self._modules:
            self._modules[self.module_path] = importlib.import_module(self.module_path)
        module = self._modules[self.module_path]
        return getattr(module, name)