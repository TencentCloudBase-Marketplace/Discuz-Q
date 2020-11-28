#!/bin/bash

function move_config() {
    # 如果没有单独映射config目录，创建config目录
    [ ! -d "/var/lib/discuz/config" ] && mkdir /var/lib/discuz/config

    # 如果config还没有创建软链接
    if [ ! -L "/var/www/discuz/config" ]; then
        # 还没有config_default.php，说明需要初始化
        if [ ! -f "/var/lib/discuz/config/config_default.php" ]; then
            cp /var/www/discuz/config/* /var/lib/discuz/config/
        fi
        mv /var/www/discuz/config /var/www/discuz/config.bak
        ln -s /var/lib/discuz/config /var/www/discuz/config
        chown -R www-data:www-data /var/www/discuz/config /var/lib/discuz/config
    fi
}

function move_storage() {
    [ ! -d "/var/lib/discuz/storage" ] && mkdir /var/lib/discuz/storage

    # 如果storage还没创建软链接
    if [ ! -L "/var/www/discuz/storage" ]; then
        # 还没有app目录，说明需要初始化
        if [ ! -d "/var/lib/discuz/storage/app" ]; then
            cp -r /var/www/discuz/storage/* /var/lib/discuz/storage/
        fi
        mv /var/www/discuz/storage /var/www/discuz/storage.bak
        ln -s /var/lib/discuz/storage /var/www/discuz/storage
        rm -f /var/www/discuz/public/storage
        ln -s /var/www/discuz/storage/app/public /var/www/discuz/public/storage
        chown -R www-data:www-data /var/www/discuz/storage /var/lib/discuz/storage /var/www/discuz/public/storage
    fi
}

LOCK_FILE=/var/lib/discuz/.clusterlock
#锁过期时间3分钟则释放
UNLOCK_TIME=180
ipaddr=`hostname -I | awk '{print $1}'`
function try_lock_for_init() {
    # 非共享情况，直接返回0，可以继续
    if [ ! -d "/var/lib/discuz" ]; then
        return 0
    fi
    destroy_lock $ipaddr
    touch $LOCK_FILE.$ipaddr

    # NFS上，ln是原子的，用ln来确保不会并发获取到锁
    ln $LOCK_FILE.$ipaddr $LOCK_FILE

    # 如果ln成功，说明能获取到锁
    if [ "$?" == "0" ]; then
        echo "lock acquired"
        trap "rm -f $LOCK_FILE; rm -f $LOCK_FILE.$ipaddr; exit" INT TERM EXIT
        return 0
    fi
    rm -f $LOCK_FILE.$ipaddr
    echo "cannot acquire lock"
    return 1
}

function destroy_lock() {
    ipaddr=${1}
     if [ -f $LOCK_FILE ]; then
         T1=`stat -c %Z $LOCK_FILE `
         T2=`date +%s`
         if [ `expr $T2 - $T1` -gt $UNLOCK_TIME ]; then
             rm -f $LOCK_FILE
         fi
    fi
    if [ -f $LOCK_FILE.$ipaddr ]; then
        T1=`stat -c %Z $LOCK_FILE.$ipaddr `
        T2=`date +%s`
        if [ `expr $T2 - $T1` -gt $UNLOCK_TIME ]; then
            rm -f $LOCK_FILE.$ipaddr
        fi
    fi
}

function init_dzq() {
    if [ ! -f "/var/www/discuz/setup.php" ]; then
        cp /usr/sbin/setup.php /var/www/discuz/setup.php
    fi
    cd /var/www/discuz && su -s /bin/sh -c "/usr/bin/php setup.php" -g www-data www-data
    if [ ! "$?" == "0" ]; then
        echo "cannot init dzq, retry in 3 seconds"
        sleep 3
        init_dzq
    fi
}


# 循环等待(其它容器的)初始化过程结束，然后才开放nginx服务
while :; do
    try_lock_for_init
    if [ "$?" == "0" ]; then
        if [ -d "/var/lib/discuz" ]; then
            move_config
            move_storage
        fi
        init_dzq
        break
    else
        echo "wait to acquire the lock file"
        sleep 5
    fi
done


rm -f $LOCK_FILE
rm -f $LOCK_FILE.$ipaddr
# 启动nginx
#/usr/sbin/supervisord ctl start nginx
/usr/sbin/supervisord -c /etc/supervisord_nginx.conf
