#!/bin/bash

case "$1" in
    start)
	nohup /bin/sh -c "/opt/ocamlmq/ocamlmq 2>&1 | logger -t ocamlmq" > /dev/null 2>&1 &
	;;
    stop)
	kill `ps auxww | grep ocamlmq | grep -v grep | grep -v kill | grep -v S21-ocamlmq | awk '{ print $2 }'`
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

