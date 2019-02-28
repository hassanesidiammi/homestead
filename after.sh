#!/bin/sh

# If you would like to do some extra provisioning you may
# add any commands you wish to this file and they will
# be run after the Homestead machine is provisioned.
#
# If you have user-specific configurations you would like
# to apply, you may also create user-customizations.sh,
# which will be run after this script.

# server_jenkins="jenkins-shiva"

# wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
# sudo apt-add-repository "deb https://pkg.jenkins.io/debian-stable binary/"


sudo apt-get update
sudo apt-get install -y php5.6-fpm php7.0-fpm php5.6-xml php5.6-mbstring php5.6-mysql php5.6-sqlite \
          php7.3-xml \
		  php7.2-xml php7.2-mbstring php7.2-mysql php7.2-sqlite
# sudo apt-get -y remove --purge openjdk*
# sudo apt autoremove -y
# sudo apt install -y openjdk-8-jdk-headless
# sudo apt-get -y install ant phpcpd
# # sudo update-alternatives --config java

# sudo apt install -y jenkins

# sudo wget  --directory-prefix=/usr/share/ http://www.phpdoc.org/phpDocumentor.phar
# sudo ln -s /usr/share/phpDocumentor.phar /usr/bin/phpdoc
# sudo chmod +x /usr/bin/phpdoc

# sudo service jenkins restart
# sudo service nginx resload
# echo jenkins and nginx reload
# sleep 30
# echo "The home directory is: $HOME"
# cd /home/vagrant/
# echo "Current directory is: $HOME"
# sudo wget -nc http://localhost:8080/jnlpJars/jenkins-cli.jar
# sudo -u jenkins cp /var/lib/jenkins/config.xml /var/lib/jenkins/config_.xml
# sudo ex +g/useSecurity/d +g/authorizationStrategy/d -scwq /var/lib/jenkins/config.xml
# echo 'ls -AlFh /var/lib/jenkins/ | grep config: '
# ls -AlFh /var/lib/jenkins/ | grep config
# sudo service jenkins restart
# sleep 60
# sudo java -jar jenkins-cli.jar -s http://localhost:8080 install-plugin \
     # checkstyle cloverphp crap4j dry htmlpublisher jdepend plot pmd violations warnings xunit git greenballs
	 # #Publish Over SSH, Audit Trail, Token Macro, Email Extension, Task Scanner,Phing, Post build task
# echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("admin", "admin")' | \
# java -jar jenkins-cli.jar -s http://localhost:8080 groovy =

# java -jar jenkins-cli.jar  -s http://127.0.0.1:8080 create-job  shiva < /home/vagrant/projects/Jenkins/shiva-main-templat.xml
# sudo -u jenkins mv -f /var/lib/jenkins/config_.xml /var/lib/jenkins/config.xml
# ls -AlFh /var/lib/jenkins/ | grep config
# sudo chown jenkins:jenkins /var/lib/jenkins/config.xml
# ls -AlFh /var/lib/jenkins/ | grep config
# sudo service jenkins restart

block='
server {
    listen 80;
    server_name mails.loc;
    location / {
      proxy_set_header        Host \$host:\$server_port;
      proxy_set_header        X-Real-IP \$remote_addr;
      proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header        X-Forwarded-Proto \$scheme;
      # Fix the "It appears that your reverse proxy set up is broken" error.
      proxy_pass          http://127.0.0.1:8025;
      proxy_read_timeout  90;
      proxy_redirect      http://127.0.0.1:8025 http://mails.loc;
      proxy_redirect      http:mails.loc:8025 http://mails.loc;
    }
  }
'

sudo block="$block" su -p - -c 'echo "$block" >> /etc/nginx/sites-available/mails.loc'
sudo ln -fs /etc/nginx/sites-available/mails.loc /etc/nginx/sites-enabled/mails.loc
sudo service nginx restart

block2="Mailhog server: ; http://mails.loc"
sudo block2="$block2" su -p - -c 'echo $block2 >> /vagrant/infos.txt'


# echo ' Provisionig Complet !!! '
# cat /vagrant/infos.txt | column -t -s '\;'

mysql -uhomestead -psecret -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'root';"

echo 'Fixing "ONLY_FULL_GROUP_BY"...';
sudo sh -c 'echo "\n" >> /etc/mysql/my.cnf;';
sudo sh -c 'echo "[mysqld]"  >> /etc/mysql/my.cnf;';
sudo sh -c 'echo "    sql_mode = \"STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION\""  >> /etc/mysql/my.cnf;';
cat /etc/mysql/my.cnf
mysql -uhomestead -psecret -e "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));"

echo 'Importing Databases !'
pv /data/shiva/backup_dump_mysql_2019-02-11_06_05.sql.gz | gunzip | mysql shiva


# sudo mysql shiva_prod < /data/shiva/sql/backup_dump_mysql_2018-10-18_12_28.sql
# sudo mysql eurorepar_china < /data/eurorepar/db_bkp/eurorepar_china_db_2018-09-20.sql
# sudo mysql eurorepar < /data/eurorepar/db_bkp/eurorepar_prod_20170925_1000.sql

