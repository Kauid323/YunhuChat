# core/__init__.py
import os
from pathlib import Path
from .lazy import LazyLoader

# 自动发现所有.py文件（排除__init__.py）
module_files = [
    f.stem for f in Path(__file__).parent.glob("*.py") 
    if f.is_file() and f.stem != "__init__"
]

# 动态创建模块访问入口
for module_name in module_files:
    globals()[module_name] = LazyLoader(f"sdk.core.{module_name}")

__all__ = list(module_files)  # 暴露所有模块