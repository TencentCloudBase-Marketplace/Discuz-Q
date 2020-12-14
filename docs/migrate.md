# 迁移 Serverless MySQL 指引
## 优点
CynosDB for MySQL 推出新的 Serverless MySQL 形态，有以下特性

1. 弹性伸缩：可配置规格范围，根据负载自动扩容，集群内可添加多个实例
2. 自动暂停：没有流量请求，最小10分钟自动暂停，暂停后停止计费(以往数据库按量付费是每个小时都收费)，存储仍然按实际使用量计费
3. 规格更小：最小 0.25 核，过往最低1核
4. 秒级计费：按秒计量，按小时结算

介绍页 https://cloud.tencent.com/document/product/1003/50853
控制台 http://console.cloud.tencent.com/cynosdb/

## 迁移文档
MySQL数据迁移指南
1. 通过DTS迁移数据 https://cloud.tencent.com/document/product/571/45488
2. 原生MySQL导出数据文件,  https://cloud.tencent.com/document/product/571/13729

## 迁移指南
### 迁移 Serverless 类型的 CynosDB 
![迁移 CynosDB](https://main.qcloudimg.com/raw/6e2352a8dd1fb210ba153f534a4673a6.jpg)

1、前往 [CynosDB](https://console.cloud.tencent.com/cynosdb) 控制台，点击 Discuz! Q 创建的DB实例管理操作，即集群名为 DiscuzCynosDB 的实例。
2、点击备份管理，进行回档操作
3、创建回档时
- 计费模式选择 serverless
- 回档模式，选择按时间点，选择当前时间
- 私有网络选择当前实例所在的私有网络
- 算力配置可以选择从 0.25 核到 0.5 核
- 自动暂停可以设置为 10 分钟
4、确认创建回档，点击立即购买
5、到列表页得到最新的内网地址

### 修改云托管的数据库配置
![云托管修改配置](https://main.qcloudimg.com/raw/3841e3fa76fd6703eb9eb1cf1ac33093.jpg)

1. 点击云托管的菜单，点击 discuzq 服务
2. 点击当前版本的 更多-调试 按钮
3. 点击打开 webshell，进入到对应的文件夹并编辑配置文件 `cd /var/lib/discuz/config;nano config.php`,参考教程 [Nano文本编辑器使用教程](https://cloud.tencent.com/developer/article/1187038)
4. 修改 `database` 的 `host` 配置