#!/bin/bash

LOCK_FILE=/var/lib/discuz/.clusterlock
#锁过期时间3分钟则释放
UNLOCK_TIME=180
ipaddr=`hostname -I | awk '{print $1}'`
function try_lock_for_run() {
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
        trap "echo 'sched trap triggered'; rm -f $LOCK_FILE; rm -f $LOCK_FILE.$ipaddr; exit" INT TERM EXIT
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

function run_sched() {
    echo "trying to run schedule"
    cd /var/www/discuz && su -s /bin/sh -c "/usr/bin/php disco schedule:run" -g www-data www-data
}


try_lock_for_run && run_sched
sleep 5
rm -f $LOCK_FILE; rm -f $LOCK_FILE.$ipaddr