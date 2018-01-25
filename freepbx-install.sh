#!/bin/bash
#install freepbx from source
set -e
sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
service sshd restart
sleep 10 
apt-get update && apt-get upgrade -y 
apt -y purge php*
apt -y install curl apt-transport-https
curl https://packages.sury.org/php/apt.gpg | apt-key add -
echo 'deb https://packages.sury.org/php/ stretch main' > /etc/apt/sources.list.d/deb.sury.org.list

install_dependinte () {
      apt install -y build-essential linux-headers-`uname -r` php5.6 php5.6-curl php5.6-cli php5.6-mysql php5.6-mbstring php5.6-gd php5.6-xml subversion htop unzip zip vim curl wget got tmux build-essential aptitude openssh-server apache2 mariadb-server mariadb-client bison doxygen flex php-pear curl sox libncurses5-dev libssl-dev libmariadbclient-dev mpg123 libxml2-dev libnewt-dev sqlite3 libsqlite3-dev pkg-config automake libtool-bin autoconf git subversion uuid uuid-dev libiksemel-dev libjansson-dev tftpd postfix mailutils nano ntp libspandsp-dev libcurl4-openssl-dev libical-dev libneon27-dev libasound2-dev libogg-dev libvorbis-dev libicu-dev libsrtp0-dev unixodbc unixodbc-dev python-dev xinetd e2fsprogs dbus sudo xmlstarlet mongodb lame ffmpeg dirmngr 



}

install_nodejs () {
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
apt -y install nodejs
}

install_dahdi() {
    cd /usr/src
    wget https://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz
    tar xf dahdi-linux-complete-current.tar.gz
    cd dahdi-linux-complete*
    make
    make install
    make config
}

install_libpri() {
    cd  /usr/src
     wget https://downloads.asterisk.org/pub/telephony/libpri/libpri-current.tar.gz
      tar xf libpri*
    cd /usr/src/libpri*
    make
    make install
   
}

install_pjsip () {
  cd /usr/src 
  wget http://www.pjsip.org/release/2.7.1/pjproject-2.7.1.tar.bz2 
  tar -xjvf pjproject-2.7.1.tar.bz2
  rm -f pjproject-2.4.tar.bz2
  cd pjproject-2.4
  CFLAGS='-DPJ_HAS_IPV6=1' ./configure --enable-shared --disable-sound --disable-resample --disable-video --disable-opencore-amr
  make dep
  make
  make install
}

install_jansson() {
 cd /usr/src
 wget http://www.digip.org/jansson/releases/jansson-2.10.tar.gz
 tar zxvf jansson-2.10.tar.gz
 cd jansson-2.10
 autoreconf -i
 ./configure
  make
  make check
  make install
}

install_asterisk() {
    pushd /usr/src
    groupadd asterisk 
    adduser asterisk --disabled-password --gecos "Asterisk User"
    mkdir /var/run/asterisk 
    chown asterisk:asterisk /var/run/asterisk
    wget http://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-current.tar.gz
    tar xf asterisk-*
    cd /usr/src/asterisk*
    contrib/scripts/get_mp3_source.sh
    contrib/scripts/install_prereq install
    ./configure --with-pjproject-bundled
    make
    make install
    make install-logrotate
    chown -R asterisk. /var/lib/asterisk
    make config 
    ldconfig 
    update-rc.d -f asterisk remove
    popd
}

install_asterisk_addons() {
    pushd /usr/src
    wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-addons-current.tar.gz
    tar xf asterisk-addons-*
    cd /usr/src/asterisk-addons*
    perl -p -i.bak -e 's/CFLAGS.*D_GNU_SOURCE/CFLAGS+=-D_GNU_SOURCE\nCFLAGS+=-DMYSQL_LOGUNIQUEID/' Makefile
    ./configure
    make clean 
    make
    make install
    popd
}

install_asterisk_sounds() {
    cd /var/lib/asterisk/sounds
    wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-wav-current.tar.gz
    wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-wav-current.tar.gz
    tar xvf asterisk-core-sounds-en-wav-current.tar.gz
    rm -f asterisk-core-sounds-en-wav-current.tar.gz
    tar xfz asterisk-extra-sounds-en-wav-current.tar.gz
    rm -f asterisk-extra-sounds-en-wav-current.tar.gz
    # Wideband Audio download 
    wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-g722-current.tar.gz
    wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-g722-current.tar.gz
    tar xfz asterisk-extra-sounds-en-g722-current.tar.gz
    rm -f asterisk-extra-sounds-en-g722-current.tar.gz
    tar xfz asterisk-core-sounds-en-g722-current.tar.gz
    rm -f asterisk-core-sounds-en-g722-current.tar.gz
}

install_freepbx(){
    cd /usr/src
    git clone -b release/14.0 --single-branch https://github.com/freepbx/framework.git freepbx
    useradd -m asterisk
    chown asterisk. /var/run/asterisk
    chown -R asterisk. /etc/asterisk
    chown -R asterisk. /var/{lib,log,spool}/asterisk
    chown -R asterisk. /usr/lib/asterisk
    rm -rf /var/www/html
    wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-13.0-latest.tgz
    tar vxfz freepbx-13.0-latest.tgz
    rm -f freepbx-13.0-latest.tgz
    cd freepbx
    ./start_asterisk start
    ./install -n
    fwconsole ma upgrade framework core voicemail sipsettings infoservices \
    featurecodeadmin logfiles callrecording cdr dashboard music conferences
       
}

echo '
    [Unit]
    Description=Freepbx
    After=mariadb.service
 
    [Service]
    Type=oneshot
    RemainAfterExit=yes
    ExecStart=/usr/sbin/fwconsole start
    ExecStop=/usr/sbin/fwconsole stop
 
    [Install]
    WantedBy=multi-user.target
    ' > /etc/systemd/system/freepbx.service 

echo '
    [MySQL]
    Description = ODBC for MySQL
    Driver = /usr/lib/x86_64-linux-gnu/odbc/libmyodbc.so
    Setup = /usr/lib/x86_64-linux-gnu/odbc/libodbcmyS.so
    FileUsage = 1
    ' > /etc/odbcinst.ini
echo '
    [MySQL-asteriskcdrdb]
    Description=MySQL connection to 'asteriskcdrdb' database
    driver=MySQL
    server=localhost
    database=asteriskcdrdb
    Port=3306
    Socket=/var/run/mysqld/mysqld.sock
    option=3
'> /etc/odbc.ini

systemctl enable freepbx

sed -i 's/upload_max_filesize = .*/upload_max_filesize = 20M/g' /etc/php/5.6/apache2/php.ini
sed -i 's/\(APACHE_RUN_USER=\)\(.*\)/\1asterisk/g' /etc/apache2/envvars
sed -i 's/\(APACHE_RUN_GROUP=\)\(.*\)/\1asterisk/g' /etc/apache2/envvars
chown asterisk. /run/lock/apache2
mv /var/www/html/index.html /var/www/html/index.html.disable
a2enmod rewrite
#main
systemctl restart apache2
echo "installation script"
cd /usr/src
install_dependinte
install_nodejs
install_dahdi
install_libpri
install_pjsip
install_jansson
install_asterisk
install_asterisk_addons
install_asterisk_sounds
install_freepbx
chkconfig httpd on
chkconfig mysqld on
service httpd restart
configure_apache2
amportal start