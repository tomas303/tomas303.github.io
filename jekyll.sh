#!/bin/bash

#bundle update

if [[ "$#" == 0 ]]; then
  CMD=serve
else
  CMD=$1
fi

case "$CMD" in
  s|serve)
    jekyll serve --watch --force_polling -t
    exit
    ;;
  b|build)
    jekyll build -t
    exit
    ;;
  n|new)
  	cd /srv/jekyll
    jekyll new . -t
    exit
    ;;
esac


