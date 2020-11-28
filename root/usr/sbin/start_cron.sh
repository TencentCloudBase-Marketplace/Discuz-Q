#!/bin/sh

echo "starting cron"
/usr/bin/crontab /etc/crontab
echo "make cron run"
exec /usr/sbin/cron -f
