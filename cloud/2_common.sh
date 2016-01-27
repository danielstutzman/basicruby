#!/bin/bash -ex

tugboat ssh basicruby <<EOF

set -ex

sudo apt-get install -y ntp
sudo service ntp restart

cp /usr/share/zoneinfo/America/Denver /etc/localtime
echo 'America/Denver' | tee /etc/timezone
/usr/sbin/dpkg-reconfigure --frontend noninteractive tzdata

sudo apt-get install -y ruby2.0 ruby2.0-dev ruby2.0-doc
gem2.0 install bundler
sudo rm /usr/bin/ruby /usr/bin/gem /usr/bin/irb /usr/bin/rdoc /usr/bin/erb
sudo ln -s /usr/bin/ruby2.0 /usr/bin/ruby
sudo ln -s /usr/bin/gem2.0 /usr/bin/gem
sudo ln -s /usr/bin/irb2.0 /usr/bin/irb
sudo ln -s /usr/bin/rdoc2.0 /usr/bin/rdoc
sudo ln -s /usr/bin/erb2.0 /usr/bin/erb

sudo apt-get install -y npm nodejs nodejs-legacy

sudo apt-get install -y mosh

sudo ufw disable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 60000:61000/udp # mosh
yes | sudo ufw enable
EOF
