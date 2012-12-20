#!/bin/bash

if [ -f "$SENCHA_SDK_TOOLS_2_0_0_BETA3/sencha" ]; then
  if [[ "$CONFIGURATION" == 'Release' ]]; then
    SENCHA_ENVIRONMENT=production
  else
    SENCHA_ENVIRONMENT=testing
  fi

  if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
    source "$HOME/.rvm/scripts/rvm"
    GEM_BIN_DIR=`rvm gemdir`/bin
  fi

  cd "$PROJECT_DIR/www"

  if [[ "$GEM_BIN_DIR" != '' && "$CONFIGURATION" == 'Release' ]]; then
    mv ./resources/css ./resources/css_dev
    "$GEM_BIN_DIR/compass" compile ./resources/sass -e production --force
  elif [[ "$GEM_BIN_DIR" != '' ]]; then
    "$GEM_BIN_DIR/compass" compile ./resources/sass -e development
  fi

  "$SENCHA_SDK_TOOLS_2_0_0_BETA3/sencha" app build -e $SENCHA_ENVIRONMENT -d ../build/www -a ../build/archive

  if [[ "$GEM_BIN_DIR" != '' && "$CONFIGURATION" == 'Release' ]]; then
    rm -rf ./resources/css
    mv ./resources/css_dev ./resources/css
  fi

  exit 0
fi

