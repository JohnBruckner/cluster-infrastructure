#!/usr/bin/expect

set timeout 30

set ipaddr [lindex $argv 0]
set old_pwd [lindex $argv 1]
set new_pwd [lindex $argv 2]

spawn -noecho ssh -q -o StrictHostKeychecking=no root@$ipaddr "passwd"
expect "assword:"
send "$old_pwd\r"
expect "*Current password"
send "$old_pwd\r"
expect "New password: "
send "$new_pwd\r"
expect "Retype new password: "
send "$new_pwd\r"
interact