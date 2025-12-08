import yh_user_sdk as sdk
# from yh_user_sdk.core.other import disk

client = sdk.set_token("YOUR_TOKEN")

# 列出文件
print(client.disk.list(
    "big", # 对象ID
    "group", # 对象类型
    folder_id = 0, # 文件夹ID,不写默认为0(根目录)
    sort = "name_asc")) # 排序方式, 不写默认 name_asc

# 创建文件夹
print(client.disk.create_folder(
    "big", # 对象ID
    "group", # 对象类型
    folder_name = "123测试", # 文件夹名称
    parent_folder_id = 0)) # 父文件夹ID,不写默认0(根目录)

data = {
    "fileSize": 0, # 文件大小
    "fileName": "测试文件", # 文件名
    "fileMd5": "123456", # 文件md5
    "fileEtag": "123456", # 文件的Etag
    "qiniuKey": "disk/123456", # 目测在七牛存储桶中的路径
    "folderId": 0 # 要上传到的文件夹ID,不写默认0(根目录)
}
print(client.disk.upload(
    "big", # 对象ID
    "group", # 对象类型
    data)) # 文件数据

# 重命名文件/文件夹
print(client.disk.rename(
    1145, # 文件(夹)ID
    "group", # 会话类型
    "114514")) # 重命名后的名称

# 删除文件(夹)
print(client.disk.remove(
    1145, # 要删除的文件(夹)ID
    "group")) # 会话类型