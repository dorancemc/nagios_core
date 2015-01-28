#!/usr/bin/perl -w

# =====================
# Script for install nagios core 
# Version 1.2
#
# dorancemc@gmail.com - 27 ene 2015

# This script install :
# - NagiosCore v4.0.8
# - NagiosPlugins v2.0.3
# - NRPE v2.15
# - PnP4Nagios v0.6.24
# - NDOUtils v2
# - NConf v1.3.0
# 
# This script will install Nagios in Debian Wheezy 
# 
# In Debian wheezy: 
# 1.- Basic installation
# 2.- Previously you need execute:
# aptitude install -y make gcc curl && perl -MCPAN -e 'install Net::Address::IP::Local' && perl -MCPAN -e 'install DBI'
# 3.- Execute
# curl -k "http://exchange.nagios.org/components/com_mtree/attachment.php?link_id=6129&cf_id=24" >install_nagios.pl
# 4.- Execute
# chmod 755 install_nagios.pl && ./install_nagios.pl
# 
#
# tested in:
# Debian 7.7
#
# tested with:
# nagios core 4.0.8
#
# =====================


# =====================
use strict;
use Config;
use File::Fetch;
use Archive::Extract;
use Net::Address::IP::Local;
use File::Copy;
use File::Path;
use DBI();

my $address = Net::Address::IP::Local->public;
my $install_tmp_path = "/tmp/nagios";
my $install_path = "/opt/nagios";
my $install_nrpe = "/opt/nrpe";
my $install_pnp4nagios = "/opt/pnp4nagios";
my $install_mklivestatus = "/opt/mk-livestatus";
my $install_nagvis = "/opt/nagvis";
my $install_ndou = "/opt/ndoutils";
my $install_nconf = "/opt/nconf";
my $user_nagios = "nagios";
my $nagios_url="http://downloads.sourceforge.net/project/nagios/nagios-4.x/nagios-4.0.8/nagios-4.0.8.tar.gz";
my $plugins_url="http://nagios-plugins.org/download/nagios-plugins-2.0.3.tar.gz";
my $nrpe_url="http://downloads.sourceforge.net/project/nagios/nrpe-2.x/nrpe-2.15/nrpe-2.15.tar.gz";
my $pnp4nagios_url="http://downloads.sourceforge.net/project/pnp4nagios/PNP-0.6/pnp4nagios-0.6.24.tar.gz"; 
my $mklivestatus_url="http://mathias-kettner.de/download/mk-livestatus-1.2.4p5.tar.gz";
my $nagvis_url="http://downloads.sourceforge.net/project/nagvis/NagVis%201.7/nagvis-1.7.10.tar.gz";
my $nsca_url="http://downloads.sourceforge.net/project/nagios/nsca-2.x/nsca-2.7.2/nsca-2.7.2.tar.gz";
my $ndou_url="http://downloads.sourceforge.net/project/nagios/ndoutils-2.x/ndoutils-2.0.0/ndoutils-2.0.0.tar.gz";
my $nconf_url="http://downloads.sourceforge.net/project/nconf/nconf/1.3.0-0/nconf-1.3.0-0.tgz";
############
my $mysql_root_passwd="p4ssw0rD";
my $mysql_root="root";
my $mysql_host="localhost";
my $mysql_db_ndou="ndoutil";
my $mysql_pass_ndou="ndoutil";
my $mysql_db_nconf="nconf";
my $mysql_pass_nconf="nconf";    
my $nagiosadmin_passwd="nagiosadm!n";
my $hostname="nagioscore";

my $distro = `lsb_release -i -s`;
chomp $distro;

my %installCmd = (
"Debian" => \&debian,
"Ubuntu" => \&ubuntu,
);

sub install_core {
  if ( exists $installCmd{$distro} ) {
    my $version = `lsb_release -r -s | cut -f1 -d "."`;
    if ( $version == 7 ) {
        $installCmd{$distro}->();
    }
    else {
        print "Unsupported Debian version... \n";
    }
  }
  else {
    print "Supported Distributions are: ". join(', ' , keys %installCmd) . ".\n";
    exit;
    }
  }

sub debian { 
    my $cmd = "";
    system ("apt-get -y update && apt-get -y upgrade") == 0 or die "can't update packages";
    $cmd = "echo mysql-server-5.5 mysql-server/root_password password $mysql_root_passwd | debconf-set-selections";
    system ($cmd);
    $cmd = "echo mysql-server-5.5 mysql-server/root_password_again password $mysql_root_passwd | debconf-set-selections";
    system ($cmd);
    system ("aptitude install -y ntp vim gcc make fping graphviz php5 apache2 php5-snmp php5-gd php5-mysql php5-ldap php5-sqlite tcpdump iptraf gvim libapache2-mod-auth-ntlm-winbind libfontconfig-dev vim-gtk libgd2-xpm-dev libltdl-dev libssl-dev mysql-server sudo rsync gawk g++ libclass-csv-perl libmysqlclient-dev") == 0 or die "can't install packages";
    system ("aptitude install -y dos2unix rrdtool librrds-perl libmcrypt-dev whois nslookup dnsutils exim4") == 0 or die "can't install packages";
    system ("aptitude install -y sysstat snmpd snmp nmap iptraf tcpdump curl") == 0 or die "can't install packages";
    my $user_apache = "www-data";
    system("echo $hostname > /etc/hostname");
    system("echo rocommunity nagios 127.0.0.1 >> /etc/snmp/snmpd.conf ");
    &add_usrgrp_nagios($user_apache);
    &installnagios(&extract_software(&down_software($nagios_url)));
    &installplugins(&extract_software(&down_software($plugins_url)));
    &installnrpe(&extract_software(&down_software($nrpe_url)));
    &installpnp4nagios(&extract_software(&down_software($pnp4nagios_url)));
    &installlivestatus(&extract_software(&down_software($mklivestatus_url)));
    &installnsca(&extract_software(&down_software($nsca_url)));
    &installndou(&extract_software(&down_software($ndou_url)));
    &installnagvis(&extract_software(&down_software($nagvis_url)),$user_apache,$user_apache);
    &installnconf(&extract_software(&down_software($nconf_url)),$user_apache);
    &isdone();
}

sub ubuntu { print "Hello from Ubuntu \n"; }

sub add_usrgrp_nagios {
    print (" Create users for nagios ... \n" );
    my $user_apache = $_[0];
    my $groupadd = "/usr/sbin/groupadd $user_nagios";
    my $nagioswww = "/usr/sbin/usermod -G $user_nagios $user_apache";
    my $useradd = "/usr/sbin/useradd $user_nagios -g $user_nagios -G $user_apache -d $install_path -m -r";
    system ($groupadd) == 0 or die "Can't add group ";
    system ($nagioswww) == 0 or die "Can't add group ";
    system ($useradd) == 0 or die "Can't add user ";
    return $?
}

sub down_software {
    my $ff = File::Fetch->new(uri => $_[0] );
    print (" Downloading ",$ff->file," ... \n" );
    my $where = $ff->fetch( to => $install_tmp_path );
    unless ( -e $where ) { print "File Doesn't Exist!"; exit;  }
    return $where;
}

sub extract_software {
    print (" Extract $_[0] ... \n" );
    my $ae = Archive::Extract->new( archive => $_[0] );
    $ae->extract( to => $install_tmp_path )  or die $ae->error; 
    return $ae->extract_path;
}

sub add_service_startup {
    system("update-rc.d -f $_[0] defaults 99");
    system("update-rc.d $_[0] enable");
}

sub installnagios {
    print (" Install Nagios Core ... \n" );
    my $cmd = "cd $_[0] ; ./configure --prefix=$install_path --with-nagios-user=$user_nagios --with-nagios-group=$user_nagios --with-cgiurl=/nagios/cgi-bin --with-htmurl=/nagios && make all && make install && make install-init && make install-commandmode && make install-config && make install-webconf && make install-exfoliation";
    system ($cmd) == 0 or die "Can't install nagios ";
    my $txt;
    $txt = "### BEGIN INIT INFO \n";
    $txt .= "# Default-Start:        2 3 4 5 \n";
    $txt .= "# Default-Stop:         0 1 6 \n";
    &fr_in_file2("/etc/init.d/nagios","### BEGIN INIT INFO",$txt);
    &fr_in_file2("/etc/init.d/nagios","### BEGIN INIT INFO",$txt);
    &fr_in_file("$install_path/etc/cgi.cfg","default_statusmap_layout=4","default_statusmap_layout=3");
    &fr_in_file("$install_path/etc/nagios.cfg","service_check_timeout_state=c","service_check_timeout_state=u");
    &fr_in_file("$install_path/etc/nagios.cfg","use_regexp_matching=0","use_regexp_matching=1");
    &create_htpasswd();
    &add_service_startup("nagios");
    &services("apache2", "restart");
    &services("nagios", "start");
    return $?;
}

sub installplugins {
    print (" Install Nagios Plugins ... \n" );
    my $cmd = "cd $_[0] ; ./configure --prefix=$install_path --with-nagios-user=$user_nagios --with-nagios-group=$user_nagios && make && make install";
    system ($cmd) == 0 or die "Can't install plugins ";
    return $?;
}

sub installnrpe {
    print (" Install NRPE ... \n" ); 
    my $cmd = "cd $_[0] ; ./configure --enable-command-args --prefix=$install_path --with-nrpe-user=$user_nagios --with-nrpe-group=$user_nagios --with-nagios-user=$user_nagios --with-nagios-group=$user_nagios --enable-ssl --with-ssl-lib=/usr/lib/x86_64-linux-gnu && make && make all && make install";
    system ($cmd) == 0 or die "Can't install NRPE ";
    system("cp $_[0]/init-script.debian /etc/init.d/nrpe && chmod 755 /etc/init.d/nrpe");
    system("cp $_[0]/sample-config/nrpe.cfg $install_path/etc/");
    &fr_in_file2("$install_path/etc/nrpe.cfg","dont_blame_nrpe=0","dont_blame_nrpe=1");
    system("echo include_dir=$install_path/etc/nrpe/ >>$install_path/etc/nrpe.cfg");
    mkdir("$install_path/etc/nrpe");
    system("/usr/bin/curl -k https://raw.githubusercontent.com/dorancemc/nagios_core/master/check.cfg >$install_path/etc/nrpe/check.cfg");
    mkdir("$install_path/libexec/other");
    system("/usr/bin/curl -k 'http://exchange.nagios.org/components/com_mtree/attachment.php?link_id=910&cf_id=24' >$install_path/libexec/other/check_cpu.sh");
    system("chmod 755 $install_path/libexec/other/check_cpu.sh");
    system("/usr/bin/curl -k 'http://exchange.nagios.org/components/com_mtree/attachment.php?link_id=4174&cf_id=24' >$install_path/libexec/other/check_mem.sh");
    system("chmod 755 $install_path/libexec/other/check_mem.sh");
    &add_service_startup("nrpe");
    &services("nrpe", "start");
    return $?;
}

sub installpnp4nagios {
    print (" Install PNP4nagios ... \n" ); 
    my $cmd = "cd $_[0] ; ./configure --with-nagios-user=$user_nagios --with-nagios-group=$user_nagios --prefix=$install_pnp4nagios && make all && make fullinstall && a2enmod rewrite"; 
    system ($cmd) == 0 or die "Can't install PNP4nagios ";
    &fr_in_file2("/etc/apache2/conf.d/pnp4nagios.conf", "/usr/local/nagios/etc/htpasswd.users", "      AuthUserFile $install_path/etc/htpasswd.users");
    rename ("$install_pnp4nagios/share/install.php", "$install_pnp4nagios/share/install.old") || die ( "Error in renaming" );
    my $txt = "process_performance_data=1 \n";
    $txt .= "# \n";
    $txt .= "host_perfdata_command=process-host-perfdata \n";
    $txt .= "service_perfdata_command=process-service-perfdata \n";
    $txt .= "# \n";
    $txt .= "service_perfdata_file=/opt/pnp4nagios/var/service-perfdata \n";
    $txt .= 'service_perfdata_file_template=DATATYPE::SERVICEPERFDATA\tTIMET::$TIMET$\tHOSTNAME::$HOSTNAME$\tSERVICEDESC::$SERVICEDESC$\tSERVICEPERFDATA::$SERVICEPERFDATA$\tSERVICECHECKCOMMAND::$SERVICECHECKCOMMAND$\tHOSTSTATE::$HOSTSTATE$\tHOSTSTATETYPE::$HOSTSTATETYPE$\tSERVICESTATE::$SERVICESTATE$\tSERVICESTATETYPE::$SERVICESTATETYPE$';
    $txt .= "\n";
    $txt .= "service_perfdata_file_mode=a \n";
    $txt .= "service_perfdata_file_processing_interval=15 \n";
    $txt .= "service_perfdata_file_processing_command=process-service-perfdata-file \n";
    $txt .= "# \n";
    $txt .= "host_perfdata_file=/opt/pnp4nagios/var/host-perfdata \n";
    $txt .= 'host_perfdata_file_template=DATATYPE::HOSTPERFDATA\tTIMET::$TIMET$\tHOSTNAME::$HOSTNAME$\tHOSTPERFDATA::$HOSTPERFDATA$\tHOSTCHECKCOMMAND::$HOSTCHECKCOMMAND$\tHOSTSTATE::$HOSTSTATE$\tHOSTSTATETYPE::$HOSTSTATETYPE$';
    $txt .= "\n";
    $txt .= "host_perfdata_file_mode=a \n";
    $txt .= "host_perfdata_file_processing_interval=15 \n";
    $txt .= "host_perfdata_file_processing_command=process-host-perfdata-file \n";
    &fr_in_file2("/opt/nagios/etc/nagios.cfg", "process_performance_data=0", $txt );

    $txt = "# \n";
    $txt .= "define command { \n";
    $txt .= " command_name process-service-perfdata-file \n";
    $txt .= ' command_line /bin/mv /opt/pnp4nagios/var/service-perfdata /opt/pnp4nagios/var/spool/service-perfdata.$TIMET ';
    $txt .= "\n";
    $txt .= "} \n";
    $txt .= " \n";
    $txt .= "define command { \n";
    $txt .= " command_name process-host-perfdata-file \n";
    $txt .= ' command_line /bin/mv /opt/pnp4nagios/var/host-perfdata /opt/pnp4nagios/var/spool/host-perfdata.$TIMET$' ;
    $txt .= "\n";
    $txt .= "} \n";
    $txt .= "\n";
    open(my $file, ">>$install_path/etc/objects/commands.cfg");
    print $file $txt;
    close($file);
    &add_service_startup("npcd");
    &services("apache2", "restart");
    &services("nagios", "restart");
    &services("npcd", "start");
    $cmd = "perl ".&down_software("http://verify.pnp4nagios.org/verify_pnp_config")." --mode=bulk --config=$install_path/etc/nagios.cfg  --pnpcfg=$install_pnp4nagios/etc/";
    system($cmd);
    return $?;
}

sub installlivestatus {
    print (" Install LiveStatus ... \n" );
    my $cmd = "cd $_[0] ; ./configure --prefix=$install_mklivestatus --with-nagios4 && make && make install"; 
    system ($cmd) == 0 or die "Can't install LiveStatus ";
    my $txt = "# \n";
    $txt .= "event_broker_options=-1 \n";
    $txt .= "broker_module=$install_mklivestatus/lib/mk-livestatus/livestatus.o $install_path/var/rw/live \n";
    &fr_in_file2("$install_path/etc/nagios.cfg", "event_broker_options", $txt );
    return $?;
}

sub installnagvis {
    print (" Install Nagvis ... \n" );
    my $cmd = "cd $_[0] ; ./install.sh -q -n $install_path -p $install_nagvis -l \"unix:$install_path/var/rw/live\" -b mklivestatus -u $_[1] -g $_[2] -w /etc/apache2/conf.d -a y"; 
    system ($cmd) == 0 or die "Can't install Nagvis ";
    &services("apache2", "restart");
    return $?;
}

sub installnsca {
    print (" Install NSCA ... \n" );
    my $cmd = "cd $_[0] ; ./configure --prefix=$install_path --with-nsca-user=$user_nagios --with-nsca-grp=$user_nagios && make all && make install"; 
    system ($cmd) == 0 or die "Can't install NSCA ";
    return $?;
}

sub installndou {
    print (" Install NDOUtils... \n" );
    my $cmd = "cd $_[0] ; ./configure --prefix=$install_ndou --with-ndo2db-user=$user_nagios --with-ndo2db-group=$user_nagios && make && make install ";
    system ($cmd) == 0 or die "Can't install NDOUtils ";
    &mysql_newdb($mysql_db_ndou, $mysql_pass_ndou);    
    $cmd = "cd $_[0]/db ; ./installdb -u $mysql_db_ndou -p $mysql_pass_ndou -h $mysql_host -d $mysql_db_ndou"; 
    system ($cmd) == 0 or die "Can't install NDOUtils database";
    $cmd = "mkdir -p $install_ndou/var/ $install_ndou/etc/";
    $cmd .= " && cp $_[0]/config/ndo2db.cfg-sample $install_ndou/etc/ndo2db.cfg";
    $cmd .= " && cp $_[0]/config/ndomod.cfg-sample $install_ndou/etc/ndomod.cfg";
    $cmd .= " && cp $_[0]/daemon-init /etc/init.d/ndo2db";
    $cmd .= " && /bin/chmod 755 /etc/init.d/ndo2db";
    $cmd .= " && /bin/chown -R $user_nagios: $install_ndou/";
    $cmd .= " && update-rc.d -f ndo2db defaults 99";
    $cmd .= " && update-rc.d ndo2db enable";
    system ($cmd) == 0 or die " Can't install NDOUtils service";
    my $txt = "event_broker_options=-1 \n";
    $txt .= "broker_module=$install_ndou/bin/ndomod.o config_file=$install_ndou/etc/ndomod.cfg";
    &fr_in_file2("$install_path/etc/nagios.cfg", "event_broker_options", $txt );
    &fr_in_file("$install_ndou/etc/ndo2db.cfg","db_name=nagios","db_name=$mysql_db_ndou");
    &fr_in_file("$install_ndou/etc/ndo2db.cfg","db_user=ndouser","db_user=$mysql_db_ndou");
    &fr_in_file("$install_ndou/etc/ndo2db.cfg","db_pass=ndopassword","db_pass=$mysql_pass_ndou");
    &add_service_startup("ndo2db");
    &services("apache2", "restart");
    &services("nagios", "stop");
    &services("ndo2db", "start");
    &services("nagios", "start");
    return $?;
}

sub installnconf {
    print (" Install Nconf ... \n" );
    my $user_apache = $_[1];
    my $cmd; 
    my $txt;
    
    $cmd = "mv $_[0] $install_nconf/ ";
    $cmd .= " && chown -R $user_apache: $install_nconf/";
    $cmd .= " && usermod $user_apache -G $user_nagios ";
    system ($cmd) == 0 or die "Can't install Nconf ";
    
    system("cp $install_nconf/config.orig/* $install_nconf/config/");
    system("cp $install_nconf/config.orig/.file_accounts.php $install_nconf/config/");
    my $tmp = $install_nconf;
    $tmp =~ s/\//\\\//g;
    &fr_in_file("$install_nconf/config/nconf.php", '$nconfdir)', "\"$tmp\")");
    &fr_in_file2("$install_nconf/config/nconf.php", "NAGIOS_BIN", "define('NAGIOS_BIN', '$install_path/bin/nagios'); ");
    &fr_in_file2("$install_nconf/config/authentication.php", "AUTH_ENABLED", "define('AUTH_ENABLED', '1'); ");
    &fr_in_file("$install_path/etc/nagios.cfg", "^cfg_file=", "#cfg_file=");
    &fr_in_file("$install_nconf/modify_attr_write2db.php", "\$max_length = \"\";", "\$max_length = \"0\";");

    &mysql_newdb($mysql_db_nconf, $mysql_pass_nconf);
    $cmd="/usr/bin/mysql -u $mysql_db_nconf -p$mysql_pass_nconf $mysql_db_nconf <$install_nconf/INSTALL/create_database.sql";
    system($cmd);
 
    $txt = "Alias /nconf  \"".$install_nconf."\" \n";
    $txt .= "\n"; 
    $txt .= "<Directory \"".$install_nconf."\"> "; 
    $txt .= "\n"; 
    $txt .= "# SSLRequireSSL \n"; 
    $txt .= "Options None \n"; 
    $txt .= "AllowOverride None \n"; 
    $txt .= "Order allow,deny \n"; 
    $txt .= "Allow from all \n"; 
    $txt .= " \n"; 
    #$txt .= "AuthName \"Nagios Access\" \n"; 
    #$txt .= "AuthType Basic \n"; 
    #$txt .= "AuthUserFile $install_path/etc/htpasswd.users \n"; 
    #$txt .= "Require valid-user \n"; 
    #$txt .= " \n"; 
    $txt .= "</Directory> \n"; 
    $txt .= " \n";
    &create_file("/etc/apache2/conf.d/nconf.conf", "$txt");
    
    $txt = "<?php \n";
    $txt .= "define('DBHOST', '$mysql_host'); \n";
    $txt .= "define('DBNAME', '$mysql_db_nconf'); \n";
    $txt .= "define('DBUSER', '$mysql_db_nconf'); \n";
    $txt .= "define('DBPASS', '$mysql_pass_nconf'); \n";
    $txt .= "?>";
    &create_file("$install_nconf/config/mysql.php", "$txt");

    $txt = "\n";
    $txt .= "[extract config] \n";
    $txt .= "type        = local \n";
    $txt .= "source_file = \"$install_nconf/output/NagiosConfig.tgz\" \n";
    $txt .= "target_file = \"$install_path/tmp/_nconf/\" \n";
    $txt .= "action      = extract \n";
    $txt .= " \n";
    $txt .= "[copy collector config] \n";
    $txt .= "type        = local \n";
    $txt .= "source_file = \"$install_path/tmp/_nconf/server/\" \n";
    $txt .= "target_file = \"$install_path/etc/server/\" \n";
    $txt .= "action      = copy \n";
    $txt .= " \n";
    $txt .= "[copy global config] \n";
    $txt .= "type        = local \n";
    $txt .= "source_file = \"$install_path/tmp/_nconf/global/\" \n";
    $txt .= "target_file = \"$install_path/etc/global/\" \n";
    $txt .= "action      = copy \n";
    $txt .= "reload_command = \"sudo /etc/init.d/nagios reload\" \n";
    $txt .= " \n";
    &create_file("$install_nconf/config/deployment.ini", "$txt");

    unlink "$install_nconf/INSTALL.php";
    rmtree("$install_nconf/INSTALL/", 1, 1);
    unlink "$install_nconf/UPDATE.php";
    rmtree("$install_nconf/UPDATE/", 1, 1);
    system("echo 'www-data ALL = (root) NOPASSWD:/etc/init.d/nagios reload' >>/etc/sudoers");
    mkdir("$install_path/etc/server");
    mkdir("$install_path/etc/global");
    system("mkdir -p $install_nconf/temp/server");
    system("mkdir -p $install_path/tmp/_nconf/server");
    system("mkdir -p $install_path/tmp/_nconf/global");
    system("chown -R www-data: $install_path/tmp/_nconf $install_path/etc/server $install_path/etc/global $install_nconf/temp/server");
    system("echo 'cfg_dir=$install_path/etc/server' >>$install_path/etc/nagios.cfg");
    system("echo 'cfg_dir=$install_path/etc/global' >>$install_path/etc/nagios.cfg");
    system("chown -R $user_apache: $install_nconf/ $install_path/etc/server $install_path/etc/global");
    &mysql_nconf_exec();
    system("chown -R $user_apache: $install_nconf/ $install_path/etc/server $install_path/etc/global");
    system("/usr/bin/curl -k https://raw.githubusercontent.com/dorancemc/nagios_core/master/nconf_base.sql >$install_tmp_path/nconf_base.sql");
    system("mysql -u $mysql_db_nconf -p$mysql_pass_nconf $mysql_db_nconf <$install_tmp_path/nconf_base.sql");
    &services("apache2", "restart");
    return $?;
}

sub create_htpasswd {
    my $cmd = "/usr/bin/htpasswd -bc $install_path/etc/htpasswd.users nagiosadmin $nagiosadmin_passwd";
    system ($cmd) == 0 or die "Can't continue without nagiosadmin passwd";
    return $?;
}

sub services {
    my $cmd="/etc/init.d/$_[0] $_[1]";
    system ($cmd);
    if ( $_[1] eq "start" || $_[1] eq "restart" )
    {
        sleep(5);
        $cmd="/etc/init.d/$_[0] status ";
        system ($cmd);
        if ( $? !=0 ) {
          print "error in $_[0] services \n";
          exit;
      }
    }
    return $?; 
}

sub fr_in_file { 
    use strict;
    my $file = $_[0];
    my $s = $_[1];
    my $r = $_[2];
    my $cmd=`sed -i 's/$s/$r/g' $file `;
    return $?;
}

sub fr_in_file2{ 
    my $file = $_[0];
    my $s = $_[1];
    my $r = $_[2];
    open(FILE,"<$file") || die "can't open file for read\n"; 
    my @lines = <FILE>;
    close(FILE);
    open(FILE,">$file")|| die "can't open file for write\n";
    foreach (@lines) 
    { if ($_ =~ /$s/) 
      { print FILE "$r \n"; }
      else
      { print FILE $_; }
    }
    close(FILE);
}

sub create_file {
    my $file = $_[0];
    open(FILE,">$file") || die "can't open file for write \n";
    print FILE $_[1];
    close(FILE);
}

sub mysql_newdb {
    my $dbh = DBI->connect("dbi:mysql:host=$mysql_host",$mysql_root, $mysql_root_passwd,{'RaiseError' => 1});
    $dbh->do("create database $_[0]") or die "can't create database $_[0]";
    $dbh->do("create user $_[0] identified by '$_[1]'") or die "can't create user $_[0]";
    $dbh->do("grant all on $_[0].* to $_[0]") or die "can't create user $_[0]";
    $dbh->disconnect();
}

sub mysql_nconf_exec {
  my $dbh = DBI->connect("DBI:mysql:database=$mysql_db_nconf;host=$mysql_host",
                         "$mysql_db_nconf", "$mysql_pass_nconf",
                         {'RaiseError' => 1});

  $dbh->do("INSERT INTO ConfigAttrs (attr_name,friendly_name,description,datatype,max_length,poss_values,predef_value,mandatory,ordering,visible,write_to_conf,naming_attr,link_as_child,link_bidirectional,fk_show_class_items,fk_id_class) VALUES ('register','register','','select','1','0::1','0','yes','26','yes','yes','no','no','no',NULL,'18');");
  $dbh->do("INSERT INTO ConfigValues (attr_value, fk_id_attr, fk_id_item) VALUES ('0', '231', 5367 ) ON DUPLICATE KEY UPDATE attr_value='0';");
  $dbh->disconnect();
}

sub isdone {
    print " =============== \n";
    print " Install finish! \n";
    print " Access to http://$address/nagios with credentials nagiosadmin/$nagiosadmin_passwd \n";
    print " pnp4nagios http://$address/pnp4nagios \n";
    print " Nagvis http://$address/nagvis with credentials admin/admin \n";
    print " Nagvis Config to http://$address/nagvis/config.php with credentials admin/admin \n";
    print " Nconf to http://$address/nconf with credentials admin/nconf \n";
    }

&install_core();
