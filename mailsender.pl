#!/usr/bin/perl
use strict;

my $email_from = qw(a@b.c);
my $server     = "smtp.server.com:port";
my $user_name  = "*****";
my $user_pass  = qw(*****);
my $theme      = "Good day to be alive, sir?";
my $message    = "Message line 1 \n" .
                 "Message line 2 \n";

my $filename   = "attachment file name";

my $cmd = "sendemail";
$cmd .= " -f '$email_from'";
$cmd .= " -u '$theme'";
$cmd .= " -s '$server'";
$cmd .= " -xu '$user_name'";
$cmd .= " -xp '$user_pass'";
$cmd .= " -a '$filename'";

#print "cmd = $cmd\n";

#my $result = `$cmd`;
#print "$result\n";

my @lines = <STDIN>;
my $all = int ((scalar @lines) / 2);
my $now = 0;
my $problems = 0;
while (@lines) {
    $now++;
    my $email = shift @lines;
    my $name  = shift @lines;

    chomp $name;
    chomp $email;

    my $current_msg = $name . " ... \n " . $message;
    my $current_cmd = $cmd . " -t '$email'" . " -m '$current_msg'";
    my $res = `$current_cmd`;

    print "$now/$all - $email ($name)\t\t\t\t\t";

    if ($res =~ /success/) {
        print ".\n";
    }  else {
        print "BAD\n";
        $problems++;
    }
    sleep 4;
}
print "DONE\n";
print "Problems: $problems\n";
