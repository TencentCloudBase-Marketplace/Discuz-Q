FROM ccr.ccs.tencentyun.com/tcb_public/ubuntu:focal

LABEL Maintainer="oldhu <me@oldhu.com>" \
      Description="Discuz! Q container with Nginx & PHP-FPM based on Ubuntu bionic."

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Asia/Shanghai

RUN apt-get update --no-install-recommends &&  \
    apt-get install -y --no-install-recommends tzdata apt-utils && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get install -y --no-install-recommends ca-certificates nano php-fpm nginx cron openssl php-mysql php-gd php-bcmath php-mbstring php-xml php-curl php-exif curl && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i '/session    required     pam_loginuid.so/c\#session    required   pam_loginuid.so' /etc/pam.d/cron

COPY root /

RUN chown -R www-data:www-data /var/www/discuz
RUN curl https://discuzq-docs-1258344699.cos.ap-guangzhou.myqcloud.com/setup.php -o /usr/sbin/setup.php

EXPOSE 80

CMD ["/usr/sbin/supervisord", "-c", "/etc/supervisord.conf"]
