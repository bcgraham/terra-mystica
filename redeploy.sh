#!bin/bash

/usr/local/apache2/bin/httpd -d /terra-mystica/www-devel -f /terra-mystica/config/apache.conf -k stop
cd / 
rm -rf /terra-mystica 
cp -R /terra-mystica-src/ /terra-mystica 
rm -rf /terra-mystica/www-devel 
cd /terra-mystica
perl deploy.pl www-devel
/usr/local/apache2/bin/httpd -d /terra-mystica/www-devel -f /terra-mystica/config/apache.conf 