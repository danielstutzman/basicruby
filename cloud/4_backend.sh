#!/bin/bash -ex

tugboat ssh basicruby <<EOF
set -ex

name=deployer group=www-data shell=/bin/bash
id -u deployer &>/dev/null || useradd deployer --gid www-data
sudo apt-get install -y nginx libpq-dev libsqlite3-dev
sudo rm -f /etc/nginx/sites-enabled/default

sudo tee /etc/nginx/sites-available/basicruby.conf <<EOF2
server {
  listen 0.0.0.0:80;
  proxy_intercept_errors off;
  server_name basicruby;
  access_log /var/log/nginx/basicruby_access_nginx.log;
  error_log /var/log/nginx/basicruby_error_nginx.log error;
  location ~ ^/(assets)/  {
    root /home/deployer/basicruby/current/public;
    gzip_static on;
    expires 1y;
    add_header Cache-Control public;
  }
  location @proxy {
    proxy_read_timeout 150;
    proxy_pass http://unix:/home/deployer/basicruby/shared/tmp/unicorn.sock;
    expires 1m;
  }
  location / {
    proxy_read_timeout 150;
    proxy_pass http://unix:/home/deployer/basicruby/shared/tmp/unicorn.sock;
    expires 1m;
  }
}
EOF2
sudo ln -sf /etc/nginx/sites-available/basicruby.conf /etc/nginx/sites-enabled/basicruby.conf
sudo service nginx restart

for ITEM in /home/deployer/basicruby \
    /home/deployer/basicruby/shared \
    /home/deployer/basicruby/shared/git \
    /home/deployer/basicruby/shared/log \
    /home/deployer/basicruby/shared/tmp \
    /home/deployer/basicruby/shared/vendor_bundle \
    /home/deployer/basicruby/releases; do
  sudo mkdir -p \$ITEM
  sudo chown deployer:www-data \$ITEM
  chmod 0755 \$ITEM
done
sudo chmod g+w /home/deployer/basicruby/shared/tmp /home/deployer/basicruby/shared/log
sudo touch /home/deployer/basicruby/shared/log/production.log
sudo chown www-data:www-data /home/deployer/basicruby/shared/log/production.log
sudo chmod 0666 /home/deployer/basicruby/shared/log/production.log
EOF

INSTANCE_IP=`tugboat droplets | grep basicruby | egrep -oh "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+" || true`
echo INSTANCE_IP=$INSTANCE_IP
scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null unicorn.initd root@$INSTANCE_IP:/etc/init.d/unicorn
echo 'sudo mkdir -p /etc/unicorn' | tugboat ssh basicruby
scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null basicruby-unicorn.conf root@$INSTANCE_IP:/etc/unicorn/basicruby.conf
scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null basicruby.unicorn.rb root@$INSTANCE_IP:/etc/unicorn/basicruby.unicorn.rb
if [ ! -e secret_key_base ]; then
  dd if=/dev/urandom bs=1 count=120 2>/dev/null | base64 > secret_key_base
fi
SECRET_KEY_BASE=`cat secret_key_base`
scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null secret_key_base root@$INSTANCE_IP:/etc/unicorn/secret_key_base
tugboat ssh basicruby <<EOF
tee -a /etc/unicorn/basicruby.unicorn.rb <<EOF2
ENV["SECRET_KEY_BASE"] = "$SECRET_KEY_BASE"
EOF2
EOF

rsync -e "ssh -l deployer -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null" -rv .. root@$INSTANCE_IP:/home/deployer/basicruby/current --exclude vendor --exclude ".*" --exclude tmp --exclude log

tugboat ssh basicruby <<"EOF"
set -ex

sudo apt-get install -y postgresql postgresql-client-common
USER_EXISTS=$(echo "\du" | sudo -u postgres psql | grep -c basicruby || true)
if [ "$USER_EXISTS" == "0" ]; then
  sudo sudo -u postgres createuser -s -e basicruby
  echo "ALTER USER basicruby WITH PASSWORD 'basicruby'" | sudo sudo -u postgres psql
fi

sudo mkdir -p /home/deployer/basicruby/current/public
if [ ! -e /home/deployer/basicruby/current/public/index.html ]; then
  echo "Backend service is running but no frontend (public dir) has been deployed yet" > /home/deployer/basicruby/current/public/index.html
fi
sudo mkdir -p /home/deployer/basicruby/current/tmp
chmod -R g+w /home/deployer/basicruby/current/tmp
chown -R deployer:www-data /home/deployer/basicruby/current
cd /home/deployer/basicruby/current
sudo apt-get install -y make g++
gem2.0 install thin -v '1.6.2'
sudo sudo -u deployer bundle install --deployment
sudo sudo -u deployer env RAILS_ENV=production bundle exec rake db:migrate
sudo sudo -u deployer env RAILS_ENV=production bundle exec rake db:seed

sudo chmod 0755 /etc/init.d/unicorn
sudo service unicorn stop || true
sleep 1
sudo service unicorn start
EOF
