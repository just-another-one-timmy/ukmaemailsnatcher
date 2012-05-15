#!/usr/bin/perl
use WWW::Mechanize;
use Error qw(:try);
use strict;

my $user_name = "*****";
my $user_pass = "*****";

my $fst_course_id = 1;
my $lst_course_id = 100;

my $mech = WWW::Mechanize->new();
my $tmp;
##################################
# Step1: log in
$mech->get("http://distedu.ukma.kiev.ua/login/index.php");
$mech->submit_form(with_fields => {
                      username => $user_name,
                      password => $user_pass
                   });
$tmp = $mech->get("http://distedu.ukma.kiev.ua/")->decoded_content;
$tmp =~ /<div class="logininfo">(.*?)<a(.*?)>(.*?)<\/a>/;
#print "Logged in as $3\n";

##################################
# Step2: go through the all courses. Seems like there are <= $lst_course_id
my @students_list_links = ();
my %students_profile_links = ();
my %name_by_mail = ();
my $base_course_url = "http://distedu.ukma.kiev.ua/course/view.php?id=";

for (my $course_id = $fst_course_id; $course_id <= $lst_course_id; $course_id++) {
    try {
        $tmp = $mech->get("$base_course_url$course_id")->decoded_content;        
    }
    # don't want to die here
    catch Error with {
        return;
    };
    if ($tmp =~ /<input type="submit" value="Yes"   \/>/) {
        #print "Found button Yes for the course $course_id:\t$1\n";
        $mech->click_button(value => "Yes");
        $tmp = $mech->get("$base_course_url$course_id")->decoded_content;
    }
    if ($tmp =~ /<a(.*?)href="(http:\/\/distedu.ukma.kiev.ua\/user\/index.php\?contextid=(.*?))">/) {
        push(@students_list_links, $2);
    }
}

#################################
# Step 3: now that we have all pages with students lists, let's go over them
foreach (@students_list_links) {
    #print "visiting $_\n";
    $tmp = $mech->get($_)->decoded_content;
    if ($mech->find_link(text_regex => qr/Show all/) != undef) {
        #print "Pressing 'Show all' button to see EVERY user on the page\n";
        $tmp = $mech->follow_link(text_regex => qr/Show all/)->decoded_content;
    }

    while ($tmp =~ /"(http:\/\/distedu.ukma.kiev.ua\/user\/view.php\?id=(.*?)course=(.*?))">/g) {
        my $link = $1;
        $link =~ s/amp;//;
        #print "Saving $link to visit later\n";
        $students_profile_links{$link} = 1;
    }

}

#################################
# Step 4: visit each student's profile and grab name and email
foreach (keys %students_profile_links) {
    my ($email, $name);
    $tmp = $mech->get($_)->decoded_content;
    $tmp =~ /"main">(.*)</;
    $name = $1;
    $tmp = $mech->content(format => 'text');
    # Works only for non-english site localization!
    if ($tmp =~ /E-mail:(.*?)[^[:ascii:]]/) {
        $email = $1;
    }
    if($tmp =~ /address:(.*?)(Courses:|Web page:|Skype |ICQ )/) {
        $email = $1;
    }
    $name_by_mail{$email} = $name;
}

#################################
# Step 5: Finally, print it out
#print "\n--- Emails: ---\n";
for my $key ( sort keys %name_by_mail) {
    print "$key\n$name_by_mail{$key}\n";
}
