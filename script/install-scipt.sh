#! /bin/bash

ruby -e "$(curl -fsSkL raw.github.com/mxcl/homebrew/go)"
\curl -L https://get.rvm.io | bash -s stable
source ~/.bash_profile
brew update
brew install libksba
brew tap homebrew/dupes
brew install autoconf automake
brew install openssl
brew install libiconv
brew install libxml2 libxslt
brew link libxml2 libxslt
brew install imagemagick
rvm --verify-downloads 1 pkg install zlib
rvm --verify-downloads 1 pkg install readline
rvm --verify-downloads 1 pkg install iconv
rvm install 1.9.3
rvm use 1.9.3 --default
cd /var/www/local_guide
bundle install
gem install passenger
passenger-install-apache2-module