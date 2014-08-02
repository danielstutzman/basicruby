# Use phusion/passenger-full as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/passenger-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/passenger-full:0.9.11

#ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update
RUN apt-get install -y -q postgresql-client libpq-dev
# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Do bundle install first so it gets cached
ADD ./Gemfile /home/app/Gemfile
ADD ./Gemfile.lock /home/app/Gemfile.lock
WORKDIR /home/app
RUN ruby-switch --set ruby2.0
RUN su app -c "bundle install --deployment"
ADD ./package.json /home/app/package.json
RUN su app -c "npm install"

ENV HOME /home/app
ENV RAILS_ENV production

# Enable Nginx and Passenger; disable default site on :80
RUN rm -f /etc/service/nginx/down /etc/nginx/sites-enabled/default
ADD basicruby.conf.template /etc/nginx/sites-available/
ADD preserve-env.conf /etc/nginx/main.d/
RUN perl -pe 's(exec /usr/sbin/nginx)(cat /etc/nginx/sites-available/basicruby.conf.template | sed "s/RAILS_ENV/\$RAILS_ENV/" > /etc/nginx/sites-enabled/basicruby.conf; exec /usr/sbin/nginx)' -i /etc/service/nginx/run
RUN perl -pe 's/# gzip_types/gzip_types/' -i /etc/nginx/nginx.conf

ADD . /home/app
RUN chown -R app /home/app
RUN su app -c "bundle exec brakeman --safe-methods yaml_loaded -z; bundle exec rake js; bundle exec rake assets:precompile"

EXPOSE 80
