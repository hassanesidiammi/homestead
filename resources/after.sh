#!/bin/sh

# If you would like to do some extra provisioning you may
# add any commands you wish to this file and they will
# be run after the Homestead machine is provisioned.
#
# If you have user-specific configurations you would like
# to apply, you may also create user-customizations.sh,
# which will be run after this script.

server_jenkins="jenkins-shiva"

wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo apt-add-repository "deb https://pkg.jenkins.io/debian-stable binary/"


sudo apt-get update
sudo apt-get -y remove --purge openjdk*
sudo apt autoremove -y
sudo apt install -y openjdk-8-jdk-headless
sudo apt-get -y install ant phpcpd
# sudo update-alternatives --config java

sudo apt install -y jenkins

sudo wget  --directory-prefix=/usr/share/ http://www.phpdoc.org/phpDocumentor.phar
sudo ln -s /usr/share/phpDocumentor.phar /usr/bin/phpdoc
sudo chmod +x /usr/bin/phpdoc

sudo service jenkins restart
sudo service nginx resload
echo jenkins and nginx reload
sleep 30
echo "The home directory is: $HOME"
cd /home/vagrant/
echo "Current directory is: $HOME"
sudo wget -nc http://localhost:8080/jnlpJars/jenkins-cli.jar
sudo -u jenkins cp /var/lib/jenkins/config.xml /var/lib/jenkins/config_.xml
sudo ex +g/useSecurity/d +g/authorizationStrategy/d -scwq /var/lib/jenkins/config.xml
echo 'ls -AlFh /var/lib/jenkins/ | grep config: '
ls -AlFh /var/lib/jenkins/ | grep config
sudo service jenkins restart
sleep 60
sudo java -jar jenkins-cli.jar -s http://localhost:8080 install-plugin \
     checkstyle cloverphp crap4j dry htmlpublisher jdepend plot pmd violations warnings xunit git greenballs
	 #Publish Over SSH, Audit Trail, Token Macro, Email Extension, Task Scanner,Phing, Post build task
echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("admin", "admin")' | \
java -jar jenkins-cli.jar -s http://localhost:8080 groovy =

java -jar jenkins-cli.jar  -s http://127.0.0.1:8080 create-job  shiva < /home/vagrant/projects/Jenkins/shiva-main-templat.xml
sudo -u jenkins mv -f /var/lib/jenkins/config_.xml /var/lib/jenkins/config.xml
ls -AlFh /var/lib/jenkins/ | grep config
sudo chown jenkins:jenkins /var/lib/jenkins/config.xml
ls -AlFh /var/lib/jenkins/ | grep config
sudo service jenkins restart

block='
server {
    listen 80;
    server_name jenkins.loc;
    location / {
      proxy_set_header        Host \$host:\$server_port;
      proxy_set_header        X-Real-IP \$remote_addr;
      proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header        X-Forwarded-Proto \$scheme;
      # Fix the "It appears that your reverse proxy set up is broken" error.
      proxy_pass          http://127.0.0.1:8080;
      proxy_read_timeout  90;
      proxy_redirect      http://127.0.0.1:8080 http://jenkins.loc;
      proxy_redirect      http:jenkins.loc:8080 http://jenkins.loc;
    }
  }
'

sudo block="$block" su -p - -c 'echo "$block" >> /etc/nginx/sites-available/jenkins.loc'
ln -fs /etc/apache2/sites-available/jenkins.loc /etc/apache2/sites-enabled/jenkins.loc
sudo service nginx restart

block2="Jenkins server: ; http://jenkins.loc"
sudo block2="$block2" su -p - -c 'echo $block2 >> /vagrant/infos.txt'


echo ' Provisionig Complet !!! '
cat /vagrant/infos.txt | column -t -s '\;'

mysql -uhomestead -psecret -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'root';"

echo 'Importing Databases !'
sudo mysql shiva < /data/shiva/sql/backup_dump_mysql_2018-09-19_17_29.sql
sudo mysql eurorepar_china < /data/eurorepar/db_bkp/eurorepar_china_db_2018-09-20.sql
sudo mysql eurorepar < /data/eurorepar/db_bkp/eurorepar-2018-08-31.sql
sudo mysql shiva_prod < /data/shiva/sql/backup_dump_mysql_2018-09-19_17_29.sql

echo 'Fixing "ONLY_FULL_GROUP_BY"...';
mysql -uhomestead -psecret -e "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));"
