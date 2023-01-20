#!/usr/bin/perl -w

use Data::Dumper;

#open($fh, '>>', '/root/assoc.log') or die;
#print $fh "Invoked\n";
#close($fh);


# This should be in a file, like the client MAC/name mappings are
my %ap_names = ( 
			'aa:aa:aa:00:00:01' => 'ap_name_1',
			'aa:aa:aa:00:00:02' => 'ap_name_2',

my %cli_names;

my $arg = $ARGV[0];

my %trap_hash;

chomp($trap_hash{'hostname'} = <STDIN>);
chomp($trap_hash{'ip_address'} = <STDIN>);

my @stack;
my @trap_temp;
my $fh;

while(<STDIN>) {
        chomp;

        if(/::/) {

                if(@stack) {

                        push @trap_temp, join(" ", @stack);
                        undef @stack;

                };

        };

        push @stack, $_;

};

push @trap_temp, join(" ", @stack);

foreach(@trap_temp) {

        s/\"//g;

        my @trap_split = split /\s/;

        my $trap_oid = shift @trap_split;
        my $trap_val = join(" ", @trap_split);

        $trap_hash{$trap_oid} = $trap_val;

};

#open($fh, '>>', '/root/trapz.txt') or die;

#print $fh ">>>$arg<<<\n";
#print $fh Dumper(%trap_hash);

#close($fh);

open($fh, '<', '/root/wifi_mac_names.txt');
while (my $line = <$fh>)
{
	my ($mac, $name) = split(' ', $line);
	$cli_names{$mac} = $name;
}

my $time = localtime();

if ($arg eq "assoc")
{
	my $cli_ip = $trap_hash{'CISCO-LWAPP-DOT11-CLIENT-MIB::cldcClientIPAddress.0'};
	my $cli_mac = $trap_hash{'CISCO-LWAPP-DOT11-CLIENT-MIB::cldcClientMacAddress.0'};
	my $cli_name;
	my $message;

	my $ap_mac = $trap_hash{'CISCO-LWAPP-DOT11-CLIENT-MIB::cldcApMacAddress.0'};
	my $ap_name = $ap_names{$ap_mac};

	my $cli_snr = $trap_hash{'CISCO-LWAPP-DOT11-CLIENT-MIB::cldcClientSNR.0'};
	my $proto = $trap_hash{'CISCO-LWAPP-DOT11-CLIENT-MIB::cldcClientProtocol.0'};

	if (exists($cli_names{$cli_mac}))
	{
		$cli_name = $cli_names{$cli_mac};
	}

	open($fh, '>>', '/root/assoc.log') or die;
	if (exists($cli_names{$cli_mac}))
	{
		print $fh "cAssoc: $time $cli_name to AP $ap_name SNR=$cli_snr proto=$proto\n";
	}
	else
	{
		print $fh "cAssoc: $time $cli_mac $cli_ip to AP $ap_name SNR=$cli_snr proto=$proto\n";
	}

	close($fh);

}

if ($arg eq "assoc2")
{
	open($fh, '>>', '/root/assoc.log') or die;

	my $cli_mac = $trap_hash{'AIRESPACE-WIRELESS-MIB::bsnStationMacAddress.0'};
	my $cli_name;
	my $cli_ip = $trap_hash{'AIRESPACE-WIRELESS-MIB::bsnUserIpAddress.0'};

	my $rad_slot = $trap_hash{'AIRESPACE-WIRELESS-MIB::bsnStationAPIfSlotId.0'};
	my $band;

	my $ap_name = $trap_hash{'AIRESPACE-WIRELESS-MIB::bsnAPName.0'};

        if (exists($cli_names{$cli_mac}))
        {
                $cli_name = $cli_names{$cli_mac};
        }

	if ($rad_slot == 0)
	{
		$band = "2.4";
	}
	elsif ($rad_slot ==1)
	{
		$band = "5";
	}
	else
	{
		$band = "?";
	}

	if ((index($ap_name, "kal") != -1) || (index($ap_name, "kew") != -1))
	{
		if (exists($cli_names{$cli_mac}))
		{
			print $fh "lAssoc: $time $cli_name to AP $ap_name band=$band\n";
		}
		else
		{
			print $fh "lAssoc: $time $cli_mac to AP $ap_name band=$band\n";
		}
	}

	close($fh);
}
