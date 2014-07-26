# Use phusion/passenger-full as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/passenger-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/passenger-full:0.9.11

#ENV DEBIAN_FRONTEND noninteractive

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

RUN apt-get -y update
RUN apt-get install -y -q postgresql-client libpq-dev
# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Do bundle install first so it gets cached
ADD ./Gemfile /home/app/Gemfile
ADD ./Gemfile.lock /home/app/Gemfile.lock
WORKDIR /home/app
RUN ruby-switch --set ruby2.0
RUN su app -c "bundle install --deployment"

ADD . /home/app
RUN chown -R app /home/app
USER app

ENV HOME /home/app
ENV RAILS_ENV development

EXPOSE 3000
