#! /usr/bin/env perl 

($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire)=getpwuid($<);

$salt=join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64];

system "stty -echo";
print STDERR "Password: ";
chomp($pword = <STDIN>);
print "\n";
system "stty echo";
$hash=crypt($pword, $salt);

print "$name:$hash:$uid:$gid:$gcos:$dir:$shell\n"
