#!/usr/bin/expect

set timeout 30

set ipaddr [lindex $argv 0]
set passwd [lindex $argv 1]

spawn -noecho ssh-copy-id root@$ipaddr 
expect "assword:"
send "$passwd\r"
interact
sleep 3