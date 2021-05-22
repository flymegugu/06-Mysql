# Mysql 学习

## 1. 基础架构

Mysql 分为两部分：

- server 层：连接器，分析器，优化器（索引选择），执行器 。包含大多数核心功能（日期，时间，数学，加密函数等），存储过程，触发器，视图等。
- 存储引擎层：负责数据的存储和提取。

mysql-5.5.5 默认存储引擎为 InnoDB。

## 2. 日志系统

### 2.1 日志模块

​ redo log（重读日志）：WAL 技术，（write ahead logging），先写日志，等合适的时候再存入磁盘，（当记录需要更新，先写入 redo log，并更新内存，等不忙的时候，innodb 引擎再写入磁盘）

redo log 是固定大小的文件，比如一组 4 个文件，单个 1g，一共 4g，可以从头到尾循环写入。

- write pos 记录写入文件的当前位置，一边写一遍后移，

- checkpoint 是擦除当前位置，一边擦一遍后移，擦除前，要把记录写入数据文件。

在 write pos 之后 和 check point 之前的部分是可以写入记录的地方。

# Mysql 学习记录

## 1.备份相关命令

### 1.1 分库备份：

1. 同时备份多个库，且有 create database 和 use database，无需提前创建库，通过 zip 压缩

```sql
#多个库会在一个sql文件中
mysqldump -B 库1 库2 | gzip >/root/t.sql.gz
```

2. 全库分库备份

```sql
 mysql -e "show databases;"|egrep -v "*_schema|*atabase"|sed -r 's@^(.*)@mysqldump -B \1|gzip >/root/\1.sql.gz@g'|bash
mysqldump -B mysql|gzip >/root/mysql.sql.gz
mysqldump -B sys|gzip >/root/sys.sql.gz
mysqldump -B testdb|gzip >/root/testdb.sql.gz
```

3. 按需求备份

```bash
#### 备份表结构
mysqldump -d testdb>t.sql
#### 备份数据
mysqldump -t testdb>t.sql
#### 分别备份 表结构 和 数据,compact减少无用输出，mysql5.6因为安全问题会报错，可以在my.cnf[mysqld]模块添加secure_file_priv =''
mysqldump 'hello' --compact -T /tmp/
mysqldump: Got error: 1290: The MySQL server is running with the --secure-file-priv option so it cannot execute this statement when executing 'SELECT INTO OUTFILE'
```

### 1.2 分表备份

​ 此时不能加-B，因为是备份多个表

```bash
mysqldump testdb 表1 表2>/root/t.sql

egrep -v "#|\*|--|^$" /root/t.sql
```

## 2. 备份知识点

1. binlog 是二进制文件，记录更新的 sql 语句信息。全备份可以增加 -F 参数来刷新 binlog 文件

```bash
mysqldump -F -B oldboy|gzip > /root/bak_$(date +%F).sql.gz
```

2. 锁定所有表备份 加上参数 -X
3. 通过 --single-transaction 对 innodb 引擎数据库进行备份会开启一个事物，这是 myisam 引擎所没有的功能。
4. 记录 binlog 位置的特殊参数， --master-data=1，当等于 1 表示备份数据中包含 change master 。。。等语句，等于 2 则表示注释这些语句，多用于主从复制，从库恢复数据使用。

5. mysqlbinlog 增量恢复工具
   可以按照时间或者位置来进行二进制内容分割到 sql 文件

```
mysqlbinlog oldboy-bin.00001 --start-position=123 -r t.sql
mysqlbinlog oldboy-bin.00001 --start-datetime='2020-02-02 11:12:21'
```

6. 恢复增量数命令

```
#多个binlog文件转换为sql
mysqlbinlog oldboy-bin.001 oldboy-bin.002 > bin.sql
#导入表中(bin.sql是增量的部分，里面还有当前库中为创建的库和表，所以可以直接导入)
mysql < bin.sql
```

7. xtrabackup 是物理机的热备，特点如下

   - 直接复制物理文件，速度快，可靠

   - 备份时候事务不间断，不会影响太多数据库性能
   - 对备份数据自动校验
   - 支持在线迁移表，快速创建新的从库
   - 几乎支持所有版本 mysql 和 mariadb

   涉及的信息：

   - .idb 文件：独立表空间存储 Innodb 引擎类型数据的文件扩展名
   - .ibdata：共享表空间存储 Innodb 引擎类型数据的文件扩展名
   - .frm：存放表结构和元数据的定义信息
   - .MYD: 存放 MyisAM 引擎表数据文件扩展名
   - .MYI:存放 MyisAM 引擎表索引文件扩展名

8. 事务性引擎 ACID 的特点：

   - 原子性：事务的所有 sql 语句，要么全成功，要么全失败

   - 一致性：事务开始前后，数据完整性不被破坏

   - 隔离性：多个事务同时访问一个数据源，事务之间是隔离，不影响彼此

   - 持久性：事务所做的都是持久化存储，数据不会丢失

## 3. 权限相关

1.

```
revoke 跟 grant 的语法差不多，只需要把关键字 “to” 换成 “from” 即可：
1 grant  all on *.* to   dba@localhost;
2 revoke all on *.* from dba@localhost;
```

2.

- DML(data manipulation language)： 数据操纵语言

它们是 SELECT、UPDATE、INSERT、DELETE，就象它的名字一样，这 4 条命令是用来对数据库里的数据进行操作的语言数据操纵语言针对于数据库表的数据，它们是 SELECT、UPDATE、INSERT、DELETE

- DDL(data definition language)：数据定义语言

有 CREATE、ALTER、DROP 等，DDL 主要是用在定义或改变表(TABLE)的结构，数据类型，表之间的链接和约束等初始化工作上，他们大多在建立表时使用

- DCL(Data Control Language)：　　　　数据控制语言

是数据库控制功能。是用来设置或更改数据库用户或角色权限的语句，包括(grant,deny,revoke 等)语句。在默认状态下，只有 sysadmin,dbcreator,db_owner 或 db_securityadmin 等人员才有权力执行 DCL

## 4.表相关

```
一、基本用法

1. 增加列

alter table tbl_name add col_name type

2. 删除列

alter table tbl_name drop col_name

3. 改变列

分为改变列的属性和改变列的名字

改变列的属性——方法1：

alter table tbl_name modify col_name type


改变列的属性——方法2：此方法可以同时改变列的名字

alter table tbl_name change old_col_name col_name type

4. 改变表的名字

alter table tbl_name rename new_tbl
```

## 5. 字符集相关

字符集：将字符转换为计算机所能识别的二进制编码方式。

校验规则：对编码进行定义和比较

每个字符集可对应多个校验规则

utf8mb4 从 5.5 开始支持，是 utf8 的扩展，兼容 ut8

## 6. 主从同步

1. 从库同步延迟原因：

- 网络问题
- 硬件差异
- 主库存在慢 sql 语句

2. 启动从库多线程

临时方式：

```bash
mysql> show processlist;

mysql> show variables like '%parallel%';
+------------------------+----------+
| Variable_name          | Value    |
+------------------------+----------+
| slave_parallel_type    | DATABASE |
| slave_parallel_workers | 0        |
+------------------------+----------+
mysql> stop slave;
mysql> set global slave_parallel_workers=4;
mysql> start slave;
mysql> show processlist;
```

永久方式：

在配置文件的[mysqld]下添加

```
slave_parallel_wockers=4
```

3. 开启从库 只读 来防止从库不被非法更新

   在[mysqld]写填写 read-only
