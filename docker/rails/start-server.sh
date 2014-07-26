#!/bin/bash
cd /home/app
bundle install
bundle exec unicorn -p 3000
