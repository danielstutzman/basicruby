#!/bin/bash -ex

tugboat ssh -n basicruby <<"EOF"

set -ex

sudo apt-get install -y rsyslog-gnutls
#curl https://papertrailapp.com/tools/syslog.papertrail.crt | sudo tee /etc/syslog.papertrail.crt
sudo curl -o /etc/papertrail-bundle.pem https://papertrailapp.com/tools/papertrail-bundle.pem

sudo tee /etc/rsyslog.d/99-papertrail.conf <<"EOF2"
# use TLS for security
$DefaultNetstreamDriverCAFile /etc/syslog.papertrail.crt # trust these CAs
$ActionSendStreamDriver gtls # use gtls netstream driver
$ActionSendStreamDriverMode 1 # require TLS
$ActionSendStreamDriverAuthMode x509/name # authenticate by hostname

# queue up to 100,000 lines if can't connect to papertrail
$ActionResumeInterval 10
$ActionQueueSize 100000
$ActionQueueDiscardMark 97500
$ActionQueueHighWaterMark 80000
$ActionQueueType LinkedList
$ActionQueueFileName papertrailqueue
$ActionQueueCheckpointInterval 100
$ActionQueueMaxDiskSpace 2g
$ActionResumeRetryCount -1
$ActionQueueSaveOnShutdown on
$ActionQueueTimeoutEnqueue 10
$ActionQueueDiscardSeverity 0

*.*          @@logs.papertrailapp.com:45259
EOF2
sudo service rsyslog restart

curl -L https://github.com/papertrail/remote_syslog2/releases/download/v0.16-beta-pkgs/remote-syslog2_0.16_i386.deb -o remote-syslog2_0.16_i386.deb
sudo dpkg -i remote-syslog2_0.16_i386.deb
sudo service remote_syslog restart
sudo curl -L https://papertrailapp.com/tools/syslog.papertrail.crt -o /etc/syslog.papertrail.crt
sudo tee /etc/log_files.yml <<EOF2
files:
  - /var/log/apache2/access.log
  - /var/log/apache2/error.log
  - /var/log/mail.log
  - /var/log/mail.err
  - /var/log/postgresql/postgresql-9.1-main.log
  - /var/log/nginx/access.log
  - /var/log/nginx/error.log
  - /var/log/nginx/todomvc_access_nginx.log
  - /var/log/nginx/todomvc_error_nginx.log
  - /var/log/postgresql/postgresql-9.3-main.log
  - /var/log/newrelic-plugin/newrelic-plugin-agent.log
  - /home/deployer/basicruby/shared/unicorn_error.log
  - /var/log/nginx/basicruby_access_nginx.log
  - /var/log/nginx/basicruby_error_nginx.log
  - /var/log/nginx/error.log
  - /var/log/ufw.log
  - /var/log/auth.log
destination:
  host: logs.papertrailapp.com
  port: 45259
ssl_server_cert: /etc/syslog.papertrail.crt
EOF2
sudo service remote_syslog restart
EOF
