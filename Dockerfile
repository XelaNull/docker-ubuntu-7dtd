FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
# In most cases there should not be a need to adjust this port. If you need to move this to a different
# port.. instead, just change your docker run command to bind this port externally to whatever port you want.
ENV TELNET_PORT=8081
ARG TELNET_PW
ENV TELNET_PW=$TELNET_PW
ARG INSTALL_DIR
ENV INSTALL_DIR=$INSTALL_DIR
RUN apt-get update -y && apt-get install wget rsync sudo git supervisor python vim software-properties-common g++ \
    apache2 php mysql-server libapache2-mod-php php-mysql cron mlocate net-tools syslog-ng telnet expect unzip sqlite3 php-sqlite3 php-gd -y

# Create beginning of supervisord.conf file
# Supervisor is needed to start all services up with this container is started
# This is very much a hack as Docker is intended to be used with micro-services model.
# I chose to design this project this way as this was the easiest way I could give a novice
# just two or three commands to create an entire server with nothing more needed than git + docker.
RUN printf '[supervisord]\nnodaemon=true\nuser=root\nlogfile=/var/log/supervisord\n' > /etc/supervisord.conf && \
# Create start_httpd.sh script
    printf '#!/bin/bash\nrm -rf /run/httpd/httpd.pid\n/usr/sbin/apachectl start' > /start_httpd.sh && \
# Create start_supervisor.sh script
    printf '#!/bin/bash\n/usr/bin/supervisord -c /etc/supervisord.conf' > /start_supervisor.sh && \
# Create syslog-ng start script    
    printf '#!/bin/bash\n/usr/sbin/syslog-ng --no-caps -F -p /var/run/syslogd.pid' > /start_syslog-ng.sh && \
# Create Cron start script    
    printf '#!/bin/bash\n/usr/sbin/cron -n\n' > /start_crond.sh && \
# Create script to add more supervisor boot-time entries
    printf '#!/bin/bash \necho "[program:$1]";\necho "process_name  = $1";\n\
echo "autostart     = true";\necho "autorestart   = false";\necho "directory     = /";\n\
echo "command       = $2";\necho "startsecs     = 3";\necho "priority      = 1";\n\n' > /gen_sup.sh

# Install rar, unrar applications
RUN wget https://www.rarlab.com/rar/rarlinux-x64-5.5.0.tar.gz && tar -zxf rarlinux-*.tar.gz && cp rar/rar rar/unrar /usr/local/bin/

# Install the Steam Application (STEAMCMD)
# Because this is Ubuntu, we can install it right from APT
RUN add-apt-repository multiverse 
RUN dpkg --add-architecture i386
RUN apt-get update -y
RUN echo steam steam/question select "I AGREE" | sudo debconf-set-selections && \
echo steam steam/license note '' | sudo debconf-set-selections && \
apt-get install lib32gcc1 steamcmd -y && \
useradd -m -s /bin/bash steam && echo steam:newpassword

# 7DTD START/STOP/SENDCMD
RUN echo '#!/bin/bash\nexport INSTALL_DIR=/data/7DTD\ncd $INSTALL_DIR\nif pidof -o %PPID -x "loop_start_7dtd.sh"; then exit; fi\n' > /loop_start_7dtd.sh && \
    printf 'while true; do if [ -f /7dtd.initialized ]; then break; fi; sleep 6; done \n' >> /loop_start_7dtd.sh && \
    printf 'while true; do \nif [[ -f $INSTALL_DIR/7DaysToDieServer.x86_64 ]] && [[ `cat $INSTALL_DIR/server.expected_status` == "start" ]]; then \n' >> /loop_start_7dtd.sh && \
    printf 'SERVER_PID=`ps awwux | grep -v grep | grep 7DaysToDieServer.x86_64`; \n' >> /loop_start_7dtd.sh && \
    printf '[[ -z $SERVER_PID ]] && $INSTALL_DIR/7DaysToDieServer.x86_64 -configfile=$INSTALL_DIR/serverconfig.xml -logfile $INSTALL_DIR/7dtd.log -quit -batchmode -nographics -dedicated; \n' >> /loop_start_7dtd.sh && \
    printf 'fi \nsleep 2 \ndone' >> /loop_start_7dtd.sh
RUN su - steam -c "(/usr/bin/crontab -l 2>/dev/null; echo '* * * * * /loop_start_7dtd.sh') | /usr/bin/crontab -"
RUN printf 'echo "start" > /data/7DTD/server.expected_status\n' > /start_7dtd.sh
RUN printf 'echo "stop" > /data/7DTD/server.expected_status\n' > /stop_7dtd.sh
RUN printf '#!/usr/bin/expect\nset timeout 5\nset command [lindex $argv 0]\n' > /7dtd-sendcmd.sh && \
    printf "spawn telnet 127.0.0.1 $TELNET_PORT\nexpect \"Please enter password:\"\n" >> /7dtd-sendcmd.sh && \
    printf "send \"$TELNET_PW\\\r\"; sleep 1;\n" >> /7dtd-sendcmd.sh && \
    printf 'send "$command\\r"\nsend "exit\\r";\nexpect eof;\n' >> /7dtd-sendcmd.sh && \
    printf 'send_user "Sent command to 7DTD: $command\\n"' >> /7dtd-sendcmd.sh
RUN printf '#!/usr/bin/php -q\n<?php\n' > /7dtd-sendcmd.php && \
    printf '$ip=exec("/sbin/ifconfig | grep broad"); $ipParts=array_Filter(explode(" ", $ip)); $cnt=0;' >> /7dtd-sendcmd.php && \
    printf 'foreach($ipParts as $part) { $cnt++; if($cnt==2) $ip=$part; }' >> /7dtd-sendcmd.php && \
    printf 'echo file_get_contents("http://$ip:8082/api/executeconsolecommand?adminuser=admin&admintoken=adm1n&raw=true&command=$argv[1]"); ?>' >> /7dtd-sendcmd.php

# Reconfigure Apache to run under steam username, to retain ability to modify steam's files
RUN sed -i 's|www-data|steam|g' /etc/apache2/envvars && \
    chown steam:steam /var/www/html -R && \
#    cd /etc/apache2/sites-enabled && ln -s ../sites-available/000-default.conf && \
    printf 'Alias "/7dtd" "/data/7DTD/html"\n<Directory "/data/7DTD">\n\tRequire all granted\n\tOptions all\n\tAllowOverride all\n</Directory>\n' > /etc/apache2/sites-enabled/001-7dtd.conf

COPY install_7dtd.sh /install_7dtd.sh
COPY 7dtd-daemon.php /7dtd-daemon.php

RUN chmod a+x /*.sh /*.php && apt-get clean

# Create different supervisor entries
RUN /gen_sup.sh syslog-ng "/start_syslog-ng.sh" >> /etc/supervisord.conf && \
    /gen_sup.sh mysqld "/start_mysqld.sh" >> /etc/supervisord.conf && \
    /gen_sup.sh crond "/start_crond.sh" >> /etc/supervisord.conf && \
    /gen_sup.sh httpd "/start_httpd.sh" >> /etc/supervisord.conf && \
    /gen_sup.sh 7dtd-daemon "/7dtd-daemon.php /data/7DTD" >> /etc/supervisord.conf

RUN mkdir /data
VOLUME ["/data"]
  
# Set to start the supervisor daemon on bootup
ENTRYPOINT ["/start_supervisor.sh"]