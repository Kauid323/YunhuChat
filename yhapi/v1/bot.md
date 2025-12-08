---
title: bot
---

未特别说明情况下请求域名均为 `https://chat-go.jwzhd.com`  
没写请求/响应项目表示不需要相关参数.  

## 机器人商店banner

POST /v1/bot/banner

请求头:  

|名称|必须|备注|
|-----|-----|-----|
|token|是|无|

响应头：

```JSONC
{
  "code": 1, // 请求状态码，1为正常
  "data": {
    "banners": [
      {
        "id": 6, // banner的id
        "title": "机器人开发指南", // 标题
        "introduction": "依托开放的服务接口，用户可以打造属于自己的机器人，提升工作生活效率", // 介绍
        "targetId": "", // "查看详情"点击后的id
        "targetUrl": "https://www.yhchat.com/document/1-3", // "查看详情"跳转的链接
        "imageUrl": "https://chat-img.jwznb.com/ca2b3753a9e7dbb94881b5f9364f7ffc.tmp", // banner背景图
        "sort": 40, // 排列顺序
        "delFlag": 0,
        "createTime": 0, // 创建时间
        "remark": "", // 备注
        "createBy": 0, // banner创建者
        "typ": 2 // 类型
      }
      // ...
    ]
  },
  "msg": "success" // 返回消息
}
```

## 机器人商店列表

POST /v1/bot/new-list

请求头:  

|名称|必须|备注|
|-----|-----|-----|
|token|是|无|

响应头：

```JSONC
{
  "code": 1, // 请求状态码，1为正常
  "data": {
    "bots": [
      {
        "chatId": "35393533", // 机器人id
        "chatType": "3", // 识别对象类别，1-用户，2-群聊，3-机器人
        "headcount": "25", // 机器人使用人数
        "nickname": "红红火火恍恍惚惚", // 机器人名字
        "introduction": "介绍介绍介绍介绍介绍介绍介绍", // 机器人介绍
        "instructions": "",
        "avatarUrl": "https://chat-img.jwznb.com/1753199311790.647github-mark.png" // 机器人头像url
      }
     // ...
    ]
  },
  "msg": "success" // 返回消息
}
```

## 使用该机器人的群组

POST /v1/bot/bot-detail

请求头:  

|名称|必须|备注|
|-----|-----|-----|
|token|是|无|

请求体：

```JSONC
{
  "id": "30473864" // 机器人id
}
```

响应体：

```JSONC
{
  "code": 1, // 请求状态码，1为正常
  "data": {
    "bot": {
      "id": 1, // 排序id（？
      "botId": "30473864", // 机器人id
      "nickname": "云湖AI助手",  //机器人名字
      "nicknameId": 151394, // 名称id
      "avatarId": 29016, // 头像id
      "avatarUrl": "https://chat-img.jwznb.com/cb1a825a1f7e4c5f782dc79200961907.png", // 头像url
      "type": 0,  // 类型
      "introduction": "官方的机器人，AI机器人。本机器人所有输出内容均由AI生成。", // 机器人介绍
      "createBy": "7058262", // 机器人创建者id
      "createTime": 1639670120, // 机器人创建时间戳
      "headcount": 115177, // 机器人使用人数
      "private": 0, // 是否私有（0为否，1为私人）
      "isStop": 0, // 是否停用（0为启用，1为停用）
      "settingJson": "",  // 设置json
      "del_flag": 0, 
      "alwaysAgree": 1, // 是否总是同意添加群聊
      "banId": 0, // 顾名思义
      "uri": "https://chat-go.jwzhd.com/open-apis/v1/bot/send?token=" // 机器人发送消息url（？
    },
    "groups": [ 
      {
        "id": 0, // 排序 （不知道为什么很多字段没有值，而客户端加入这个群显示群聊信息正常）
        "groupId": "161466900", // 群组id
        "name": "每日科技", // 群聊名字
        "introduction": "每天分享互联网科技信息", // 群聊介绍
        "createBy": "", // 群聊创建者id
        "createTime": 0, // 群聊创建时间
        "avatarId": 0, // 群聊头像id
        "del_flag": 0,
        "avatarUrl": "https://chat-img.jwznb.com/6eedb15cae0e7ddc59e8ae19a234c33c.png", // 群聊头像url
        "headcount": 0, // 群聊人数
        "readHistory": 0, // 是否启用新成员查看历史记录
        "alwaysAgree": 0, // 是否总是直接加入群聊
        "categoryId": 0, // 类别id
        "category": "", // 类别
        "private": 0, // 群聊是否私有
        "banId": 0, // ban人的id
        "gag": 0,
        "gagBy": "",
        "msgTypeLimit": ""
      },
    // ...
  ],
  "msg": "success" // 返回消息
}
```

## 获取创建的所有机器人信息

POST /v1/bot/bot-group-list

请求头:  

|名称|必须|备注|
|-----|-----|-----|
|token|是|无|

响应体：

```JSONC
{
  "code": 1, // 请求状态码，1为正常
  "data": {
    "botsTotal": 1, // 机器人数量
    "list": {
      "bots": [
        {
          "id": 0,
          "botId": "75282754", // 机器人id
          "nickname": "语录助手【复活版】123", // 机器人名称
          "nicknameId": 0,
          "avatarId": 0,
          "avatarUrl": "https://chat-img.jwznb.com/ca97fe72dda09b217071e3ab70497bf7.jpg", // 机器人头像url
          "token": "595968d7ce9241c4bb549ba2b4f5add9", // 机器人token
          "link": "http://xg.3.frp.one:16967", // 机器人消息订阅地址
          "introduction": "使用 wsu2059 的开源项目搭建基于ErisPulse SDK服务器来自我的戴尔笔记本inspiron 11-3148项目地址：https://github.com/wsu2059q/App-DailyQuoteReminder", // 机器人简介
          "createBy": "",
          "createTime": 0,
          "headcount": 0,
          "private": 0,
          "uri": "https://chat-go.jwzhd.com/open-apis/v1/bot/send?token=", // 机器人发送消息示例接口（可以展示并且复制，token=后面跟着机器人的token）
        },
      ]
    }
  },
  "msg": "success" // 返回消息
}
```

## 更改机器人设置

POST /v1/bot/edit-setting-json

请求头:  

|名称|必须|备注|
|-----|-----|-----|
|token|是|无|

请求体：

```JSONC
{
  "id": "123", // 机器人id
  "settingJson": "[]" // 机器人设置json，需转义
}
```

响应体：

```JSONC
{
  "code": 1, // 请求状态码，1为正常
  "msg": "success" // 返回消息
}
```

## 更改机器人信息

POST /v1/bot/web-edit-bot

请求头:  

|名称|必须|备注|
|-----|-----|-----|
|token|是|无|

请求体：

```JSONC
{
  "nickname":"测试机器人名称", // 机器人名称
  "introduction":"测试机器人简介", // 机器人简介
  "avatarUrl":"https://...", //机器人头像url  
  "botId":"123", // 机器人ID
  "private":0 // 0-公开，1-私有
}
```

响应体：

```JSONC
{
  "code": 1, // 请求状态码，1为正常
  "msg": "success" // 返回消息
}
```

## 获取机器人信息

POST /v1/bot/bot-info

请求头:  

|名称|必须|备注|
|-----|----|----|
|token|是|无|

请求体:  

```ProtoBuf
id: 123 // 机器人ID
```

::: details ProtoBuf数据结构

```proto
message bot_info_send {
    string id = 2; // 机器人ID
}
```

:::

响应体:  

```ProtoBuf
status {
  number: 114514
  code: 1
  msg: "success"
}
Bot_data {
  bot_id: "123" // 机器人ID
  name: "测试机器人名称" // 机器人名称
  name_id: 123 // 机器人名称ID
  avatar_url: "https://..." // 机器人头像url
  avatar_id: 123 // 机器人头像ID
  introduction: "测试机器人介绍" // 机器人介绍
  create_by: "123" // 机器人创建者ID
  create_time: 123123123 // 机器人创建时间戳
  headcount: 123 // 使用人数
  private: 0 // 是否为私有，0-公开，1-私有
  is_stop: 0 // 是否停用，0-启用，1-停用
  always_agree: 0 // 自动进群，0-不自动进群，1-自动进群
  do_not_disturb: 0 // 免打扰，0-不免打扰，1-免打扰
  top: 0 // 置顶，0-未置顶，1-已置顶
  group_limit: 0 // 限制进群，0-允许进群，1-限制进群
}
```

::: details ProtoBuf数据结构

```proto
// 获取机器人信息返回信息
message bot_info {
    Status status = 1;
    Bot_data data = 2;
    message Bot_data {
        string bot_id = 1; // 机器人ID
        string name = 2; // 机器人名称
        int64 name_id = 3; // 机器人名称ID
        string avatar_url = 4; // 机器人头像url
        string avatar_id = 5; // 机器人头像ID
        string introduction = 6; // 机器人介绍
        string create_by = 7; // 机器人创建者ID
        int64 create_time = 8; // 机器人创建时间戳
        int64 headcount = 9; // 使用人数
        int32 private = 10; // 是否为私有，0-公开，1-私有
        int32 is_stop = 11; // 是否停用，0-启用，1-停用
        int32 always_agree = 13; // 自动进群，0-不自动进群，1-自动进群
        int32 do_not_disturb = 15; // 免打扰，0-不免打扰，1-免打扰
        int32 top = 18; // 置顶，0-未置顶，1-已置顶
        int32 group_limit = 20; // 限制进群，0-允许进群，1-限制进群
    }
}

```

:::

## 获取机器人群聊看板

POST /v1/bot/board

请求头:  

|名称|必须|备注|
|-----|----|----|
|token|是|无|

请求体:  

```ProtoBuf
id: 123 // 群聊ID
chat_type: 2 // 对象类型 1-用户 2-群聊 3-机器人
```

::: details ProtoBuf数据结构

```proto
// 看板
message board_send {
    string id = 3; // 群聊/用户/机器人ID
    int64 chat_type = 4; // 对象类型 1-用户 2-群聊 3-机器人
}
```

:::

响应体:  

```ProtoBuf
status {
  number: 114514
  code: 1
  msg: "success"
}
Board_data {
  bot_id: "123" // 机器人ID
  chat_id: "123" // 对象ID
  chat_type: 2 // 对象类别，2-群聊，3-机器人
  content: "测试看板内容" // 看板内容
  content_type = 5; // 看板内容类别，1-文本，2-markdown，3-html
  last_update_time: 123123123 // 最后更新时间戳
  bot_name: "测试机器人名称" // 设置看板机器人名称
}
```

::: details ProtoBuf数据结构

```proto
// 获取看板返回
message board {
    Status status = 1;
    Board_data data = 2;
    message Board_data {
        string bot_id = 1; // 机器人ID
        string chat_id = 2; // 对象ID
        int32 chat_type = 3; // 对象类别，2-群聊，3-机器人
        string content = 4; // 看板内容
        int32 content_type = 5; // 看板内容类别，1-文本，2-markdown，3-html
        int64 last_update_time = 6; // 最后更新时间戳
        string bot_name = 7; // 设置看板机器人名称
    }
}
```

:::

## 删除用户对机器人的添加

POST /v1/bot/remove-follower

请求头:  

|名称|必须|备注|
|-----|-----|-----|
|token|是|机器人管理员token|

请求体：

```JSONC
{
  "botId": "123", // 机器人ID
  "userId": "123" // 用户ID
}
```

响应体：

```JSONC
{
  "code": 1, // 请求状态码，1为正常
  "msg": "success" // 返回消息
}
```

## 删除群聊对机器人的添加

POST /v1/bot/remove-group

请求头:  

|名称|必须|备注|
|-----|-----|-----|
|token|是|机器人管理员token|

请求体：

```JSONC
{
  "botId": "123", // 机器人ID
  "groupId": "123" // 群聊ID
}
```

响应体：

```JSONC
{
  "code": 1, // 请求状态码，1为正常
  "msg": "success" // 返回消息
}
```

## 获取可用AI模型列表

POST /v1/bot/llm/llm-setting-list

请求头:  

|名称|必须|备注|
|-----|-----|-----|
|token|是|无|

响应体：

```JSONC
{
  "code": 1, // 请求状态码，1为正常
  "data": {
    "list": [
      {
        "icon": "https://...", // 模型组图标
        "id": 1, // 模型组ID
        "name": "测试AI大模型", // 模型组名称
        "params": "[{\"name\": \"API Key\", \"type\": \"input\"}]", // 参数模板
        "parent_id": 0, // 参数ID
        "subItems": [
          {
            "icon": null, // 模型图标
            "id": 161, // 模型ID
            "name": "测试AI大模型-chat", // 模型名称
            "params": "[{\"name\": \"API Key\", \"type\": \"input\"}]", // 参数模板
            "parent_id": 1, // 参数模板ID
            "subItems": null,
            "tag": "测试模型数据" // tag数据，若无则为null
          }
          // ...
        ],
        "tag": "测试模型数据" // tag数据，若无则为null
      }
      // ...
    ],
  "msg": "success" // 返回消息
}
```

## 获取机器人大模型设置

POST /v1/bot/llm/llm-setting-ref-info

请求头:  

|名称|必须|备注|
|-----|-----|-----|
|token|是|机器人管理员token|

请求体：

```JSONC
{
  "botId": "123", // 机器人ID
}
```

响应体：

```JSONC
{
  "code": 1, // 请求状态码，1为正常
  "data": {
    "historyCount": 0,
    "id": 0,
    "isBigModel": 0, // 是否开启大模型，0-关闭，1-开启
    "isNeedReply": 0,
    "key": "", // 大模型APIkey
    "llmBaseUrl": "",
    "llmId": 0, // 大模型组ID
    "llmModelName": "测试大模型-chat", // 大模型名称
    "llmName": "测试大模型", // 大模型组名称
    "mcpJson": "", // mcpJSON数据，json转义
    "paramJson": "", // paramJSON数据，json转义
    "prompt": "" // AI提示词
  },
  "msg": "success" // 返回消息
}
```

## 重置机器人token

POST /v1/bot/reset-bot-token

请求头:  

|名称|必须|备注|
|-----|-----|-----|
|token|是|机器人管理员token|

请求体：

```JSONC
{
  "botId": "75282754", // 机器人ID
}
```

响应体：

```JSONC
{
  "code": 1, // 请求状态码，1为正常
  "data": {
    "token": "07bda1762e2340d2add1b27844xxxxxx" // 机器人token
  },
  "msg": "success" // 返回消息
}
```

## 设置机器人消息订阅

POST /v1/event/edit

请求头:  

|名称|必须|备注|
|-----|-----|-----|
|token|是|机器人管理员token|

请求体：

```JSONC
{
  "botId": "75282754", // 机器人id
  "messageReceiveNormal": 1, // 普通消息事件，1开启，0-关闭
  "messageReceiveInstruction": 0, // 指令消息事件，1开启，0-关闭
  "botFollowed": 1, // 关注机器人事件，1开启，0-关闭
  "botUnfollowed": 1, // 取关机器人事件，1开启，0-关闭
  "groupJoin": 1, // 加入群事件，1开启，0-关闭
  "groupLeave": 1, // 退出群事件，1开启，0-关闭
  "botSetting": 1, // 机器人设置消息事件，1开启，0-关闭
  "typ": "messageReceiveInstruction" // 每次机器人设置的key值，为该请求2-8的key值中的一个
}
```

响应体：

```JSONC
{
  "code": 1, // 请求状态码，1为正常
  "msg": "success" // 返回消息
}
```

## 获取机器人消息订阅设置

POST /v1/event/list

请求头:  

|名称|必须|备注|
|-----|-----|-----|
|token|是|机器人管理员token|

请求体：

```JSONC
{
  "botId": "75282754"
}
```


响应体:

```JSONC
{
  "code": 1, // 请求状态码，1为正常
  "data": {
    "list": {
      "id": 3247, // 设置id
      "botId": "75282754", // 机器人id
      "messageReceiveNormal": 1, // 普通消息事件，1开启，0-关闭
      "messageReceiveInstruction": 0, // 指令消息事件，1开启，0-关闭
      "botFollowed": 1, // 关注机器人事件，1开启，0-关闭
      "botUnfollowed": 1, // 取关机器人事件，1开启，0-关闭
      "groupJoin": 1, // 加入群事件，1开启，0-关闭
      "groupLeave": 1, // 退出群事件，1开启，0-关闭
      "botSetting": 1, // 机器人设置消息事件，1开启，0-关闭
      "del_flag": 0 // 是否被删除，0-没有，1-被删除
    }
  },
  "msg": "success" // 返回消息
}
```

## 设置机器人消息订阅接口

POST /v1/bot/edit-subscribed-link

请求头:  

|名称|必须|备注|
|-----|-----|-----|
|token|是|机器人管理员token|

请求体：

```JSONC
{
  "botId": "75282754", // 机器人id
  "link": "http://xg.3.frp.one:16967" // 设置消息订阅接口（地址）
}
```

响应体：
```JSONC
{
  "code": 1, // 请求状态码，1为正常
  "msg": "success" // 返回消息
}
```

## 获取机器人指令列表（网页控制台）

POST /v1/instruction/web-list

请求头:  

|名称|必须|备注|
|-----|-----|-----|
|token|是|无|

请求体：

```JSONC
{
  "botId": "45669202" // 机器人id
}
```

响应体：
```JSONC
{
  "code": 1, // 请求状态码，1为正常
  "data": {
    "list": [
      {
        "id": 2062, // 指令Id
        "botId": "45669202", // 机器人id
        "name": "普通指令", // 指令名称
        "desc": "指令描述", // 指令描述
        "instructionType": 1, // 指令类型，1-普通指令，2-直发指令，5-自定义输入指令，更多（如下两个指令）
        "hintText": "输入框提示文字", // 输入框提示文字
        "defaultText": "输入框默认文字", // 输入框默认文字
        "customJson": "", // 自定义输入指令json数组
        "createTime": 0, // 创建时间戳
        "sort": 0, // 排序
        "hidden": 0 // 是否隐藏(0-显示，1-隐藏)
      },
      {
        "id": 2063,
        "botId": "45669202",
        "name": "直发指令",
        "desc": "指令描述",
        "instructionType": 2,
        "hintText": "",
        "defaultText": "",
        "customJson": "",
        "createTime": 0,
        "sort": 0,
        "hidden": 0
      },
      {
        "id": 2064,
        "botId": "45669202",
        "name": "自定义输入指令",
        "desc": "指令描述",
        "instructionType": 5,
        "hintText": "",
        "defaultText": "",
        "customJson": "[{\"key\":0,\"type\":\"radio\",\"title\":\"Radio 单选框\",\"propsValue\":{\"label\":\"标签\",\"options\":\"用#分割，比如：北京#上海#天津\"},\"props\":[{\"type\":\"label\",\"name\":\"标签\",\"value\":\"\"},{\"type\":\"options\",\"name\":\"选项\",\"placeholder\":\"用#分割，如：北京#上海#天津\",\"value\":\"\"}],\"id\":\"ykwmdt\"}]",
        "createTime": 0,
        "sort": 0,
        "hidden": 0
      }
    ]
  },
  "msg": "success" // 返回消息
}

::: details 自定义输入指令部分解释

```jsonc
[{
  "key": 0,
  "type": "radio",
  "title": "Radio 单选框",
  "propsValue": { // propsValue是成品，保存了当前组件实际生效的配置数据。用于组件在页面上显示和运行。
    "label": "标签",
    "options": "用#分割，比如：北京#上海#天津"
  },
  "props": [{ // prop是蓝图，定义了可以配置什么，以及默认值是什么。用于渲染一个配置界面。
    "type": "label", // 类型，一个用于设置“标签”的配置项，有radio-单选框，input-输入框，switch-开关，chexkbox-多选框，textarea-多行输入框，select-选择器
    "name": "标签", // 显示给用户的名字叫“标签”
    "value": "" // 这个type预定的值，默认空
  }, {
    "type": "options",
    "name": "选项", // 显示给用户的名字叫“选项”
    "placeholder": "用#分割，如：北京#上海#天津", // 输入框里的提示文字，通常只有Radio-单选框，Checkbox-多选框，Select-选择器会有这个key
    "value": ""
  }],
  "id": "ykwmdt" // 该表单的id
}]
```

:::

## 创建机器人指令

POST /v1/instruction/create

请求头:  

|名称|必须|备注|
|-----|-----|-----|
|token|是|无|

请求体：

```JSONC
{
  "name": "名称", // 指令名称
  "desc": "描述", // 指令描述
  "hintText": "输入框提示文字", // 输入框提示文字 
  "defaultText": "输入框默认文字", // 输入框默认文字
  "type": 1, // 指令类型，1-普通指令，2-直发指令，5-自定义输入指令
  "botId": "45669202" // 机器人id
}
```

响应体：

```JSONC
{
  "code": 1, // 请求状态码，1为正常
  "msg": "success" // 返回消息
}
```

## 编辑机器人指令

POST v1/instruction/edit

请求头:  

|名称|必须|备注|
|-----|-----|-----|
|token|是|无|

请求体：

```JSONC
{
  "id": 2064, // 已有的指令id
  "name": "自定义输入指令", // 指令名称
  "desc": "指令描述", // 指令描述
  "botId": "45669202", // 机器人id
  "customJson": "", // 自定义输入指令（表单指令），只有type为5的自定义输入指令需要，这个是json数组，需转意，具体设置可以看 **获取机器人指令列表（网页控制台）** 对一些表单指令的解释
  "type": 5, // 指令类型，1-普通指令，2-直发指令，5-自定义输入指令
  "delFlag": 0
}
```

响应体：

```JSONC
{
  "code": 1, // 请求状态码，1为正常
  "msg": "success" // 返回消息
}
```

下面是json转意示例:
```JSONC
{
  "id": 2064,
  "name": "自定义输入指令",
  "desc": "指令描述",
  "botId": "45669202",
  "customJson": [ // 自定义输入指令
    {
      "key": 0, // 单选框表单对应的key，0-单选框，1-输入框，2-开关，3-多选框，4-多行输入框，5-选择器
      "type": "radio", // 类型
      "title": "Radio 单选框", // 类型标题
      "propsValue": {
        "label": "单选框", // 标签
        "options": "用#分割，如：北京#上海#天津" // 选项，选项用#分割，如：北京#上海#天津
      },
      "props": [
        {
          "type": "label", // 类型（标签）
          "name": "标签", // 类型名称
          "value": ""
        },
        {
          "type": "options", // 类型（选项）
          "name": "选项", // 类型名称
          "placeholder": "用#分割，如：北京#上海#天津", // 类型占位符
          "value": ""
        }
      ],
      "id": "rxpuwl" // 表单id（为6为随机生成小写字母）
    },
    {
      "key": 1,
      "type": "input",
      "title": "Input 输入框",
      "propsValue": {
        "label": "输入框",
        "defaultValue": "默认内容",
        "placeholder": "占位文本"
      },
      "props": [
        {
          "type": "label",
          "name": "标签",
          "value": ""
        },
        {
          "type": "defaultValue", // 默认值
          "name": "默认内容",
          "value": ""
        },
        {
          "type": "placeholder",
          "name": "占位文本",
          "value": ""
        }
      ],
      "id": "rngnti"
    },
    {
      "key": 2,
      "type": "switch",
      "title": "Switch 开关",
      "propsValue": {
        "label": "开关",
        "defaultValue": "1-打开，0-关闭"
      },
      "props": [
        {
          "type": "label",
          "name": "标签",
          "value": ""
        },
        {
          "type": "defaultValue",
          "name": "默认状态",
          "placeholder": "1：默认打开，0：默认关闭",
          "value": ""
        }
      ],
      "id": "ckemfz"
    },
    {
      "key": 3,
      "type": "checkbox",
      "title": "Checkbox 多选框",
      "propsValue": {
        "label": "多选框",
        "options": "用#分割，如：北京#上海#天津"
      },
      "props": [
        {
          "type": "label",
          "name": "标签",
          "value": ""
        },
        {
          "type": "options",
          "name": "选项",
          "placeholder": "用#分割，如：北京#上海#天津",
          "value": ""
        }
      ],
      "id": "gnsllv"
    },
    {
      "key": 4,
      "type": "textarea",
      "title": "textarea 多行输入框",
      "propsValue": {
        "label": "多行输入框",
        "placeholder": "占位文本"
      },
      "props": [
        {
          "type": "label",
          "name": "标签",
          "value": ""
        },
        {
          "type": "placeholder",
          "name": "占位文本",
          "value": ""
        }
      ],
      "id": "wssejf"
    },
    {
      "key": 5,
      "type": "select",
      "title": "Select 选择器",
      "propsValue": {
        "label": "选择器",
        "options": "用#分割，如：北京#上海#天津"
      },
      "props": [
        {
          "type": "label",
          "name": "标签",
          "value": ""
        },
        {
          "type": "options",
          "name": "选项",
          "placeholder": "用#分割，如：北京#上海#天津",
          "value": ""
        }
      ],
      "id": "mzqmon"
    },
    {
      "key": 5,
      "type": "select",
      "title": "Select 选择器",
      "propsValue": {
        "label": "222",
        "options": "3333"
      },
      "props": [
        {
          "type": "label",
          "name": "标签",
          "value": ""
        },
        {
          "type": "options",
          "name": "选项",
          "placeholder": "用#分割，如：北京#上海#天津",
          "value": ""
        }
      ],
      "id": "alfkvr"
    }
  ],
  "type": 5,
  "delFlag": 0
}
```