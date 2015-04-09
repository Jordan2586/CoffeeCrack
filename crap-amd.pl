#!/usr/bin/env perl

#     ____         __   __               ____                    _
#    / ___| ___   / _| / _|  ___   ___  / ___| _ __  __ _   ___ | | __
#   | |    / _ \ | |_ | |_  / _ \ / _ \| |    | '__|/ _` | / __|| |/ /
#   | |___| (_) ||  _||  _||  __/|  __/| |___ | |  | (_| || (__ |   <
#    \____|\___/ |_|  |_|   \___| \___| \____||_|   \__,_| \___||_|\_\
#

# CRAP script - Coffeecrack Reporting And Processing script.
# For AMD cards with oclHashcat 1.32
# Updated 2015-04-08
# Get the latest version at: https://github.com/Jordan2586/CoffeeCrack/
#
# Copyright (C) 2015 Jordan Walsh <jordan.walsh@protonmail.ch>
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use warnings;
use strict;
use Cwd;
use Switch; #Package libswitch-perl required

my (@path, #Contains what directories should be scanned for .hash files
	@files, #Contains files found when scanning directories
	@done, #Contains contents of .done file
	$hashcat, #Location of hashcat executable
	$dict, #location of dictionary
	$mask, #Location of masks
	$out, #Location of output file
	$pot, #Location of hashcat pot file
	$html, #Location of completed reports
	$date, #Current date/time for reports
	$sel, #Selection of menu 1
	$sel2, #Selection of menu 2
	$mode, #Hash type
	$attack, #Attack Mode
	$switch, #Optional switches
	$usernames, #0 = no users in outfile 1 = users in outfile.
	$timer, #Keeps track how long a test has been going for. (in seconds)
	$length, #Average password length
	$found, #Number of found hashes
	$total, #Number of total hashes
	$perc, #percent of the found hashes
	$small, #amount of users who have small passwords
	@smallusers, #users who have small passwords.
	$symbols, #amount of users who dont have symbols
	@symbolsusers, #users who have no symbols in their passwords.
	$numbers, #amount of users who dont have numbers in their passwords.
	@numbersusers, #users who dont have numbers in their passwords.
	$figlet, #ASCII art
	@lines, #Stores each line from outfile
	@currentline, #Stores info from the current @lines, separated at 
	@hash, #Stores all hash values from outfile
	@pass, #Stores all passwords from outfile
	@user); #Stores all users from outfile


#Set default variables
@path = ('/ftp', cwd());
$hashcat = glob('~/oclHashcat-1.32/oclHashcat64.bin');
$pot = glob('~/oclHashcat.pot');
$out = glob('~/out.txt');
$mask = glob('~/coffeecrack.hcmask');
$dict = glob('~/dict');
$html = ('/var/www/html'); #/var/www/html in ubuntu, /var/www in debian
$mode = ('1000');
$attack = ('0');
$switch = ('');
$figlet = `figlet CoffeeCrack`; #package figlet required

&mymenu();

sub mymenu #Menu options for myswitch()
	{
		`touch $pot`;
		`touch .done`;
		`sed -i '\/\^\\s\*\$\/d' .done`; #Removes empty lines in done file. '/^$/ d'

		system("clear");
		print ("$figlet");
		print ("*** CoffeeCrack Reporting And Processing script ***\n\n");
		&myformat("1) About","");
		&myformat("2) Edit Options","");
		&myformat("3) View completed files","");
		&myformat("4) View reports (in browser)","");
		&myformat("5) Autorun","");
		&myformat("6) RUN!!!","");
		print "\n";
		&myswitch();
	}

sub mymenu2 #Menu options for myswitch2()
	{
		system("clear");
		print ("*** CoffeeCrack Reporting And Processing script ***\n\n");
		&myformat("1) Back to main menu","");
		print "\n";
		&myformat("2) Edit Hashcat Location","$hashcat");
		&myformat("3) Edit pot file location","$pot");
		&myformat("4) Edit dictionary location","$dict");
		&myformat("5) Edit masks location","$mask");
		&myformat("6) Edit output file location","$out");
		&myformat("7) Edit reports location","$html");
		print "\n";
		&myformat("8) Edit paths to scan","@path");
		&myformat("9) Edit hash type","$mode");
		&myformat("10) Edit attack type","$attack");
		&myformat("11) Edit additional switches","$switch");
		print "\n";
		&myformat("12) Clear pot file",`wc -l $pot|cut -d ' ' -f1`);
		&myformat("13) Clear completed files",`wc -l .done|cut -d ' ' -f1`);
		print "\n";
		&myswitch2();
	}

sub myswitch
	{
		print ("Make a selection: ");
		chomp ($sel = <STDIN>);

		switch ($sel)
		{
			case 1 		{ system("clear"); #About
						system ("echo 'The Crap menu provides an easy to use interface to process hashes using 
Hashcat, and create reports, saving them to the local web server. 
Once GIT has been installed, you can download the latest version 
of the crap script by typing:

git clone https://github.com/Jordan2586/CoffeeCrack

You can update the scripts by entering the CoffeeCrack directory 
and typing:

git pull

By default, Crap scans 2 directories for .hash files: /ftp and the 
directory which crap was run in. Once a file has been processed, its 
name will be placed in a file called .done, so that it is not 
processed a second time. This done file can be deleted manually, or 
in the “Edit Options” menu. The “Edit Options” menu will also allow 
you to specify the location of hashcat, the attack mode of hashcat, 
the location of the reports, among other options. The information 
provided on the right side of the menu are the current value(s) of 
that option, or its current size if applicable. Note that changing 
these values will not change the defaults that are set in the script 
itself. The Crap menu is able to detect whether or not usernames are 
included in the hash file, and is able to include that information 
in the generated report.

Press q to quit.'|less");
						}

			case 2		{&mymenu2();} #Edit Options

			case 3 		{ system("clear"); #View completed files
						open(my $fh, "<", ".done") or die "$!";
						print <$fh>;
						close $fh or die "$!";
						print "\nPress ENTER to continue";
						<STDIN>;}

			case 4 		{ `/usr/bin/firefox https://127.0.0.1`;} #View reports (in browser)

			case 5 		{ system("clear"); #Autorun
						while (1==1)
						{&myhash();
						sleep(30);} }

			case 6 		{ system("clear"); #RUN!!!
						&myhash();}

			case "exit"	{exit;}

			case "quit"	{exit;}

			case "alex"	{$figlet = `figlet Greasy Midget`;} #totally not an easter egg.

			else 		{print "Invalid selection.\n";
						&myswitch();}
		}
	&mymenu();
	}

sub myswitch2
	{
		print ("Make a selection: ");
		chomp ($sel2 = <STDIN>);

		switch ($sel2)
		{
			case 1 		{&mymenu();} #Back to main menu

			case 2 		{ system("clear"); #Edit Hashcat Location
						print "Enter the full path for oclHashcat32.bin or oclHashcat64.bin: \n";
						chomp ($hashcat = <STDIN>);}

			case 3		{ system("clear"); #Edit pot file location
						print "Enter the location of the hashcat pot file:\n";
						chomp ($pot = <STDIN>);}

			case 4		{ system("clear"); #Edit dictionary location
						print "Enter the location of the dictionary file or dictionary folder:\n";
						chomp ($dict = <STDIN>);}

			case 5		{ system("clear"); #Edit masks location
						print "Enter the location of mask file mask folder:\n";
						chomp ($mask = <STDIN>);}

			case 6 		{ system("clear"); #Edit output file location
						print "Enter the full path for the output file:\n";
						chomp ($out = <STDIN>);}

			case 7 		{ system("clear"); #Edit output file location
						print "Enter the path to put completed reports:\n";
						chomp ($html = <STDIN>);}

			case 8 		{ system("clear"); #Edit paths to scan
						print "Enter the path(s) to look for .hash files.\n";
						print "Seperate paths with space:\n";
						chomp (@path = split(' ',<STDIN>));}

			case 9 		{ system("clear"); #Edit hash type
						print "Enter the hash type you want to use.\n";
						print "Go to http://hashcat.net/wiki/doku.php?id=oclhashcat for details.\n";
						print "Hint: NTLM=1000, MD5=0\n";
						print ("Make a selection: \n");
						chomp ($mode = <STDIN>);}

			case 10		{ system("clear"); #Edit attack type
						print "0 = Straight\n1 = Combination\n3 = Brute-force/mask attack\n6 = Hybrid dict + mask\n7 = Hybrid mask + dict\nEnter the attack mode:\n";
						chomp ($attack = <STDIN>);}

			case 11		{ system("clear"); #Edit additional switches
						print "Enter any additional switches:\n";
						chomp ($switch = <STDIN>);}

			case 12		{ system("clear"); #Clear pot file
						 `rm $pot`;
						 `touch $pot`;
						print "The pot file has been cleared.\nPress ENTER to continue";
						<STDIN>;}

			case 13 	{ system("clear"); #Clear completed files
						 `rm .done`;
						 `touch .done`;
						print "The done file has been cleared.\nPress ENTER to continue";
						<STDIN>;}

			case "exit"	{exit;}

			case "quit"	{exit;}

			else		{print "Invalid selection.\n";
						&myswitch2();}
		}
	&mymenu2();
	}

sub myhash
	{
		open(my $fh, "<", ".done") or die "$!";
		while(<$fh>)
		{
			push @done, $_;
		}
		close $fh or die "$!";
		foreach (@path)
		{
			push @files,`find $_ -maxdepth 1 -name '*.hash'`;
		}
		foreach (@files)
		{
			if ($_ ~~ @done)
			{
				chomp $_;
				print "Found the file \"$_\" (already processed.)\n";
			}
			else
			{
				chomp $_;
				print "Found the file \"$_\"\n";
				`rm $out`;
				`touch $out`;
				$switch = ('');
				$usernames = ((`head -n 1 $_`) =~ tr/:/:/); #detects if there are users in the input file

				if ($usernames == 1)
				{
					$switch = "--username";
				}

				switch ($attack)
					{
						case 0	#Straight attack (dictionary)
								{chomp ($timer = `date +"%s"`);
								system("$hashcat -m $mode -a $attack $switch -o $out $_ $dict");}

						case 1	#Combination Attack (2 dictionaries)
								{chomp ($timer = `date +"%s"`);
								system("$hashcat -m $mode -a $attack $switch -o $out $_ $dict $dict");}

						case 3	#Brute force/mask attack (mask only)
								{chomp ($timer = `date +"%s"`);
								system("$hashcat -m $mode -a $attack $switch -o $out $_ $mask");}

						case 6	#Hybrid dict + mask
								{chomp ($timer = `date +"%s"`);
								system("$hashcat -m $mode -a $attack $switch -o $out $_ $dict $mask");}

						case 7	#Hybrid mask + dict
								{chomp ($timer = `date +"%s"`);
								system("$hashcat -m $mode -a $attack $switch -o $out $_ $mask $dict");}

						else
								{print "Invalid mode selected.";
								&mymenu;}
					}
				`echo '$_' >> .done`;
				if ($usernames == 1)
					{
						`touch .temp`;
						`$hashcat --username --show $_ > .temp`;
						`mv .temp $out`;
						`sed -i '\/\\x0d/g' $out`; #Fixes hashcat's end of lines
						`sed -i '1d' $out`;
					}
				`sed -i '\/\\x0d/g' $out`; #Fixes hashcat's end of lines
				$total = `wc -l $_|cut -d ' ' -f1`;
				&report;
			}

		}
		@done = (); #reset variables back to default
		@files = ();

	}

sub report
	{
		@lines = ();
		@user = ();
		@hash = ();
		@pass = ();
		@currentline = ();
		$length = ();
		$perc = ();
		$small = (0);
		@smallusers = ();
		$symbols = (0);
		@symbolsusers = ();
		$numbers = (0);
		@numbersusers = ();
		open (my $fh, "<", $out) or die "$!";
		while (<$fh>)
		{
			$_ =~ s/\$/\\\$/g; #Adds escape characters to passwords that cause problems.
			$_ =~ s/\"/\\\"/g;
			$_ =~ s/\:/\/g; #Changes split character to BELL (0x07)
			if ($usernames == 1)
				{
					$_ =~ s/\:/\/; #do it again if required.
				}
								#(This is to protect against users with : in their password.)
			if ($_ =~ m/\S/) #Yet another check for whitespace
			{
				push @lines, $_;
			}
		}
		close $fh or die "$!";

		foreach (@lines)
		{
			@currentline = (split(/\/, $_));

			if ($usernames != 1) #without usernames
			{
				push @hash, $currentline[0];
				push @pass, $currentline[1];
				$length += length($currentline[1]);
				if (length($currentline[1]) < 6)
					{
						$small++;
					}
				if ($currentline[1] !~ m/[a..z|A..Z|0..9]/)
					{
						$symbols++;
					}
				if ($currentline[1] !~ m/\d+/)
					{
						$numbers++;
					}
			}

			if ($usernames == 1) #with usernames
			{
				push @user, $currentline[0];
				push @hash, $currentline[1];
				push @pass, $currentline[2];
				$length += length($currentline[2]);
				if (length($currentline[2]) < 6)
					{
						$small++;
						push @smallusers, $currentline[0];
					}
				if ($currentline[2] !~ m/[a..z|A..Z|0..9]/)
					{
						$symbols++;
						push @symbolsusers, $currentline[0];
					}
				if ($currentline[2] !~ m/\d+/)
					{
						$numbers++;
						push @numbersusers, $currentline[0];
					}
			}
		}
		$found = (scalar @pass);
		$length = ($length / $found);
		$length = (sprintf "%.2f", $length); #round to 2 decimals
		$perc = (($found / $total) * 100);
		$perc = (sprintf "%.2f", $perc);
		chomp ($date = `date +"%F %T"`);
		chomp ($timer = `date +"%s"` - $timer);
		$timer = ($timer / 60); #seconds to minutes
		$timer = (sprintf "%.2f", $timer);
		`touch "$html/Report at $date\.html"`;
		`echo '<!DOCTYPE html>
<html>
<head>
<style>
table, th, td {
	border: 1px solid black;
	border-collapse: collapse;
}
th, td {
	padding: 5px;
}
</style>
<h1>Report of file $out at $date.</h1>
</head>
<body>
<p><b>We found $found of the $total hashes. ($perc %) </b><br/>
<b>The average password length is $length characters. </b><br/>
<b>It took $timer minutes to process the hashes.</b><br/>
<b>$small of users have passwords under 6 characters.</b> (@smallusers) <br/>
<b>$symbols of users have no symbols in their passwords.</b> (@symbolsusers) <br/>
<b>$numbers of users have no numbers in their passwords.</b> (@numbersusers) <br/> </p></hr></br>
<table style="width:100%">' >> "$html/Report at $date\.html"`;

		if ($usernames == 0) #no usernames
		{
			`echo "<tr>
	<th>Hash</th>
	<th>Password</th>
</tr>" >> "$html/Report at $date\.html"`;

			for (my $i=0; $i <= $#hash; $i++)
			{
				`echo "<tr><td>$hash[$i]</td>" >> "$html/Report at $date\.html"`;
				`echo "<td>$pass[$i]</td></tr>" >> "$html/Report at $date\.html"`;
			}
		}

		if ($usernames == 1) #usernames
		{
			`echo "<tr>
	<th>Username</th>
	<th>Hash</th>
	<th>Password</th>
</tr>" >> "$html/Report at $date\.html"`;

			for (my $i=0; $i <= $#hash; $i++)
			{
				`echo "<tr><td>$user[$i]</td>" >> "$html/Report at $date\.html"`;
				`echo "<td>$hash[$i]</td>" >> "$html/Report at $date\.html"`;
				`echo "<td>$pass[$i]</td></tr>" >> "$html/Report at $date\.html"`;
			}
		}

		`echo "</table>
</body>
</html>" >> "$html/Report at $date\.html"`;

	}

sub myformat #Formats 2 strings to align left & right on the same line
	{
format STDOUT =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<@>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
"$_[0]", "$_[1]"
.
write();
	}
