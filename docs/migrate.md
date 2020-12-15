## 迁移到 Serverless MySQL 指引

### Serverless 形态的优点

CynosDB for MySQL 推出新的 Serverless MySQL 形态，有以下特性

1. 弹性伸缩：可配置规格范围，根据负载自动扩容，集群内可添加多个实例
2. 自动暂停：没有流量请求，最小 10 分钟自动暂停，暂停后停止计费(以往数据库按量付费是每个小时都收费)，存储仍然按实际使用量计费
3. 规格更小：最小 0.25 核，过往最低 1 核
4. 秒级计费：按秒计量，按小时结算

介绍页 https://cloud.tencent.com/document/product/1003/50853
控制台 http://console.cloud.tencent.com/cynosdb/

MySQL 数据迁移指南

1. 通过 DTS 迁移数据 https://cloud.tencent.com/document/product/571/45488
2. 原生 MySQL 导出数据文件, https://cloud.tencent.com/document/product/571/13729

### 迁移指南

Discuz! Q 当前部署采用的是按量付费的 CynosDB for MySQL 实例。是按小时收费，即使没有流量也不会自动缩容到 0，会持续收费。
当前推出新的 Serverless 形态，没有连接自动会暂停，不再计费。因此，推荐迁移到该方案。

#### 1、迁移数据到 Serverless 类型的 CynosDB

1、前往 [CynosDB](https://console.cloud.tencent.com/cynosdb) 控制台，点击 Discuz! Q 创建的 DB 实例管理操作，即集群名为 DiscuzCynosDB 的实例。
![管理](https://main.qcloudimg.com/raw/7468b97f3a16294c90feaf9e9f66e456.jpg)
2、点击备份管理，进行回档操作
![管理](https://main.qcloudimg.com/raw/f6b8c62f0d97f36005b9bcd644514d66.jpg)
3、创建回档，确认创建回档，点击立即购买
![创建回档](https://main.qcloudimg.com/raw/b5d0c183a78f0f73e7197c1bbb8850b2.jpg)

- 计费模式选择 serverless
- 回档模式，选择按时间点，选择当前时间
- 私有网络选择当前实例所在的私有网络
- 算力配置可以选择从 0.25 核到 0.5 核
- 自动暂停可以设置为 10 分钟
  4、到列表页得到最新的内网地址
  ![新实例](https://main.qcloudimg.com/raw/0887318901e638a7c81cafd250e74e9c.jpg)

#### 2、修改云托管的数据库配置，指向新的数据库

1. 点击云托管的菜单，点击 discuzq 服务
   ![discuzq](https://main.qcloudimg.com/raw/60ec5608e757a3436f529f028fa75b30.jpg)
2. 点击当前版本的 更多-调试 按钮
   ![调试](https://main.qcloudimg.com/raw/f705a7713733f9cba5d6beee22926d11.jpg)
3. 点击打开 webshell，进入到对应的文件夹并编辑配置文件 `cd /var/lib/discuz/config;nano config.php`,参考教程 [Nano 文本编辑器使用教程](https://cloud.tencent.com/developer/article/1187038)
   ![编辑配置文件](https://main.qcloudimg.com/raw/4dd8e89a17f853636dd05942adb3f18d.png)
4. 修改 `database` 的 `host` 配置，保存文件。
   ![修改host配置](https://main.qcloudimg.com/raw/9a8ce9974ea66aa745a6b3ca81a5579f.png)

#### 3、校验是否迁移成功

1. 将 serverless 数据库设置为暂停
   ![数据库暂停](https://main.qcloudimg.com/raw/21422b519faa82a8d27ba119cc3efa0f.jpg)
2. 访问 Discuz! Q 站点，出现如下失败界面，即代表已经指向新的 DB。刷新后，访问成功。DQ 将会在下个版本适配数据库重连，不会再出现如下报错。
   ![访问DQ站点失败](https://main.qcloudimg.com/raw/341e587ca76a51862869c13a3a275219.jpg)
3. 再检查数据库集群状态，应该变更为”运行中“
4. 可以将原先的数据库删除，并前往回收站删除。

### 缩容的逻辑

1. 如果站点一直没有流量访问，云托管将于半小时内缩容到 0。
2. DQ 的应用程序会有天级、分钟级的定时任务脚本，脚本里有请求数据库。因此，数据库会在云托管缩容到 0 后 10 分钟触发暂停。