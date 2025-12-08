### 0.1.13
新增 msg 的引用图片 url,引用视频 url,提示信息.  
WS 加入 stream_message 支持.  

### 0.1.12
tool 新增 get_msg  

### 0.1.11
ws 新增 bot_board_message 事件反序列化.  
bot 新增 board
group 新增 bot_list

### 0.1.10
修正 bot 的 proto 中 avatar_id 类型.  
新增 sticker, 目前支持 list, add, remove, sort, detail.  
新增 expression, 目前支持 list, create, add, delete, topping.  
新增 sticky, 目前支持 list, add, delete, top  

### 0.1.9
修正 msg 的 button_report 对按钮值的变量命名.  
新增 bot 的 info, bot_group_list.  
新增 group.tag 的 member(s).

### 0.1.8
更新群云盘相关接口的SDK.  

### 0.1.7
添加超时时间设定,需要在初始化时设定 timeout 参数,当前版本部分模块默认超时时间(没写的是没超时时间设定的参数):  

|模块名|默认超时时间|
|--------|---------------|
|msg|60s|
|group|10s|

更新 user.proto, 加入解封时间相关描述.  
更新 web.py, 加入部分接口.  