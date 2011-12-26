#!/bin/bash

case "$1" in
    start)
	nohup /opt/ocamlmq/ocamlmq > /dev/null 2>&1 &
	;;
    stop)
	kill `ps auxww | grep ocamlmq | grep -v grep | awk '{ print $2 }'`
	;;
    restart)
	$0 stop
	sleep 1
	$0 start
	;;
    *)
	echo "Unknown option"
	exit 1
	;;
esac

exit 0


#!/bin/sh


