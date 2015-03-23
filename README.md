#VIRTUAL HOSTING WITH PUREFTPD + MYSQL AUTHENTICATION + TLS/SSL INCLUDE QUOTA AND BANDWIDTH MANAGEMENT
(Environment: CentOS-6.6-x86_64-minimal.iso)

+This document describes how to install a PureFTPd server that uses virtual users from a MySQL database instead of real system users. 
+This is much more performance and allows to have thousands of ftp users on a single machine. 
+In addition to that I will show the use of quota and upload/download bandwidth limits with this setup. 
+Passwords will be stored encrypted as MD5 strings in the database.

#######################
0/ENVIRONMENT PREPARING
	OS: CentOS-6.6-x86_64-minimal.iso
	IP: 192.168.0.100
	NETMASK: 255.255.255.0
	GATEWAY: 192.168.0.1
	
	#IP ADDRESS:
	root@srv148 ~# cat /etc/sysconfig/network-scripts/ifcfg-eth0 
	DEVICE=eth0
	HWADDR=00:25:90:E7:39:AE
	TYPE=Ethernet
	UUID=397d7416-4e1f-4c04-ab0d-38936eb846c7
	ONBOOT=yes
	NM_CONTROLLED=yes
	#BOOTPROTO=dhcp
	BOOTPROTO=none
	IPADDR=192.168.0.100
	NETMASK=255.255.255.0
	GATEWAY=192.168.0.1

	#DNS CONFIG:
	root@srv148 ~# cat /etc/resolv.conf
	nameserver 8.8.8.8
	nameserver 8.8.4.4
	nameserver 210.245.0.11
	nameserver 210.245.1.253
	nameserver 210.245.1.254
	
	#DISABLE IPv6:
	To set it permanently on system boot I put the setting also in /etc/sysctl.conf:
		echo "net.ipv6.conf.default.disable_ipv6=1" >>/etc/sysctl.conf
		echo "net.ipv6.conf.all.disable_ipv6=1" >>/etc/sysctl.conf
	Approved new config: 
		#sysctl -p
	nano /etc/sysconfig/network
		NETWORKING_IPV6=no
		IPV6INIT=no
	
	#REBOOT:
		#reboot
		
	#UPDATE DATE/TIME:
	install ntp:
		#yum install ntp ntpdate ntp-doc	
	Turn on service, enter:
		#chkconfig ntpd on
	Synchronize the system clock with 0.pool.ntp.org server (use this command only once or as required):
		#ntpdate -s time.nist.gov
	Start the NTP server. The following will continuously adjusts system time from upstream NTP server. No need to run ntpdate
		#/etc/init.d/ntpd start
	
	#INSTALL NANO:
		#yum install nano		
	
	#CONFIG GLOBAL PATH:
		#nano /etc/profile
			####################################
			export PS1="\u@\h \w# "
			export HISTTIMEFORMAT='%F %T  '
			export EDITOR=nano
			####################################			
			PATH=/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/script
			export PATH 
			PATH=$PATH:/opt/jdk1.8.0_25/bin:/opt/script:/opt/lampp/bin
			export PATH		
			
			CLASSPATH=$CLASSPATH:/opt/jdk1.8.0_25/jre/lib:/opt/jdk1.8.0_25/jre/lib/ext:.
			export CLASSPATH
			
			JAVA_HOME=/opt/jdk1.8.0_25
			export JAVA_HOME

			JRE_HOME=/opt/jdk1.8.0_25/jre
			export JRE_HOME
			####################################
			#Update PATH: source /etc/profile  #
			####################################
		
#######################
1/INSTALLATION MYSQL DB
First we enable the EPEL repository on our CentOS system as some packages that we are going to install in the course of this tutorial are not available in the official CentOS 6.4 repositories:
rpm --import https://fedoraproject.org/static/0608B895.txt
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -ivh epel-release-6-8.noarch.rpm
yum install yum-priorities
#
Edit /etc/yum.repos.d/epel.repo...
vi /etc/yum.repos.d/epel.repo
... and add the line priority=10 to the [epel] section:
[epel]
name=Extra Packages for Enterprise Linux 6 - $basearch
#baseurl=http://download.fedoraproject.org/pub/epel/6/$basearch
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch
failovermethod=priority
enabled=1
priority=10
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
[...]
#
Now we can install MySQL and phpMyAdmin as follows:
yum install mysql mysql-server
#
Then we create the system startup links for MySQL:
chkconfig --levels 235 mysqld on
/etc/init.d/mysqld start
#
Create a password for the MySQL user root (replace yourrootsqlpassword with the password you want to use):
mysql_secure_installation
[root@server1 ~]# mysql_secure_installation
	NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MySQL
	      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!
	
	In order to log into MySQL to secure it, we'll need the current
	password for the root user.  If you've just installed MySQL, and
	you haven't set the root password yet, the password will be blank,
	so you should just press enter here.
	
	Enter current password for root (enter for none): <-- ENTER
	OK, successfully used password, moving on...
	
	Setting the root password ensures that nobody can log into the MySQL
	root user without the proper authorisation.
	
	Set root password? [Y/n] <-- ENTER
	New password: <-- yourrootsqlpassword
	Re-enter new password: <-- yourrootsqlpassword
	Password updated successfully!
	Reloading privilege tables..
	 ... Success!
	
	By default, a MySQL installation has an anonymous user, allowing anyone
	to log into MySQL without having to have a user account created for
	them.  This is intended only for testing, and to make the installation
	go a bit smoother.  You should remove them before moving into a
	production environment.
	
	Remove anonymous users? [Y/n] <-- ENTER
	 ... Success!
	
	Normally, root should only be allowed to connect from 'localhost'.  This
	ensures that someone cannot guess at the root password from the network.
	
	Disallow root login remotely? [Y/n] <-- ENTER
	 ... Success!
	
	By default, MySQL comes with a database named 'test' that anyone can
	access.  This is also intended only for testing, and should be removed
	before moving into a production environment.
	
	Remove test database and access to it? [Y/n] <-- ENTER
	 - Dropping test database...
	 ... Success!
	 - Removing privileges on test database...
	 ... Success!
	
	Reloading the privilege tables will ensure that all changes made so far
	will take effect immediately.
	
	Reload privilege tables now? [Y/n] <-- ENTER
	 ... Success!	

Cleaning up...
#
All done!  If you've completed all of the above steps, your MySQL
installation should now be secure.

Thanks for using MySQL!

#######################
2/INSTALLATION PUREFTPD
The CentOS PureFTPd package supports various backends, such as MySQL, PostgreSQL, LDAP, etc. Therefore, all we have to do is install the normal PureFTPd package: 
#yum install pure-ftpd
#
Then we create an ftp group (ftpgroup) and user (ftpuser) that all our virtual users will be mapped to. Replace the group- and userid 2001 with a number that is free on your system:
#groupadd -g 2001 ftpgroup
#useradd  -u 2001 -s /bin/false -d /bin/null -c "pureftpd user" -g ftpgroup ftpuser
#
Create The MySQL Database For PureFTPd
Now we create a database called pureftpd and a MySQL user named pureftpd which the PureFTPd daemon will use later on to connect to the pureftpd database:
#mysql -u root -p
mysql>CREATE DATABASE pureftpd;
mysql>GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP ON pureftpd.* TO 'pureftpd'@'localhost' IDENTIFIED BY 'ftpdpass';
mysql>FLUSH PRIVILEGES;
#
Replace the string ftpdpass with whatever password you want to use for the MySQL user pureftpd. Still on the MySQL shell, we create the database table we need (yes, there is only one table!):
mysql>USE pureftpd;
mysql>CREATE TABLE IF NOT EXISTS `ftpd` (
  `id` int(3) NOT NULL AUTO_INCREMENT,
  `user` varchar(16) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `password` varchar(64) COLLATE utf8_unicode_ci NOT NULL DEFAULT '2e4e106f70093bd3ef9b9d4c62acc14f' COMMENT 'md5(''310212'')',
  `uid` varchar(11) COLLATE utf8_unicode_ci NOT NULL DEFAULT '2002' COMMENT 'nginx uid: 2002',
  `gid` varchar(11) COLLATE utf8_unicode_ci NOT NULL DEFAULT '2002' COMMENT 'nginx gid: 2002',
  `ipaccess` varchar(15) COLLATE utf8_unicode_ci NOT NULL DEFAULT '*' COMMENT '*-all | 192.168.1.0/24 | ...',
  `ulbandwidth` smallint(5) NOT NULL DEFAULT '1024' COMMENT 'ULBandwidth: 1024 KB/sec ~ 1 MB/s | 0-unlimited',
  `dlbandwidth` smallint(5) NOT NULL DEFAULT '1024' COMMENT 'DLBandwidth: 1024 KB/sec ~ 1 MB/s | 0-unlimited',
  `quotasize` bigint(10) NOT NULL DEFAULT '4096' COMMENT 'in MB, 10240000~10.000GB',
  `quotafiles` int(11) NOT NULL DEFAULT '0' COMMENT '0 means unlimited.',
  `status` enum('0','1') COLLATE utf8_unicode_ci NOT NULL DEFAULT '1' COMMENT '1-enable | 0-disable',
  `createdtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'now()',
  `lastupdate` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'now()',
  `expirieddate` datetime NOT NULL COMMENT 'Su dung MySQL Event de cau hinh status=0',
  `comments` varchar(10000) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'desc',
  `dir` varchar(254) COLLATE utf8_unicode_ci NOT NULL DEFAULT '/opt/gluster-storage/www/' COMMENT '/opt/gluster-storage/www/',
  PRIMARY KEY (`user`),
  UNIQUE KEY `User` (`user`),
  UNIQUE KEY `id` (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='-- status: 1-enable | 0-disable\r\n-- password: md5(''<string>'')\r\n-- uid: 2001\r\n-- gid: 2001\r\n-- dir: /opt/xampp_www/manga247.com\r\n-- ULBandwidth: 1024 KB/sec ~ 1 MB/s\r\n-- DLBandwidth: 1024 KB/sec ~ 1 MB/s\r\n-- comment: ftp user manga247_com\r\n-- ipaccess: *-all | 192.168.1.0/24 | ...\r\n-- QuotaSize: 4096 MB\r\n-- QuotaFiles: 0 means unlimited.';
#
-- #################
-- INSERT INTO `ftpd` (`User`, `status`, `Password`, `Uid`, `Gid`, `Dir`, `ULBandwidth`, `DLBandwidth`, `comment`, `ipaccess`, `QuotaSize`, `QuotaFiles`) 
-- VALUES ('exampleuser', '1', MD5('secret'), '2001', '2001', '/home/www.example.com', '100', '100', '', '*', '50', '0');
-- UID: The userid of the ftp USER you created AT the END of step two (e.g. 2001).
-- GID: The groupid of the ftp GROUP you created AT the END of step two (e.g. 2001).
-- Dir: The home DIRECTORY of the virtual PureFTPd USER (e.g. /home/www.example.com). 
-- 	IF it does NOT exist, it will be created WHEN the NEW USER LOGS IN the FIRST TIME via FTP. 
-- 	The virtual USER will be jailed INTO this home DIRECTORY, i.e., he cannot access other directories outside his home directory.
-- 
-- +ULBandwidth:   Upload bandwidth of the virtual USER IN KB/sec. (kilobytes per SECOND). 0 means unlimited.
-- +DLBandwidth: Download bandwidth of the virtual USER IN KB/sec. (kilobytes per SECOND). 0 means unlimited.
-- COMMENT: You can enter ANY COMMENT here (e.g. FOR your internal administration) here. Normally you LEAVE this FIELD empty.
-- 
-- ipaccess: Enter IP addresses here that are allowed TO connect TO this FTP account. * means ANY IP address IS allowed TO connect.
-- 
-- QuotaSize: STORAGE SPACE IN MB (NOT KB, AS IN ULBandwidth AND DLBandwidth!) the virtual USER IS allowed TO USE ON the FTP server. 0 means unlimited.
-- QuotaFiles: amount of files the virtual USER IS allowed TO save ON the FTP server. 0 means unlimited.
###########################################
3/CONFIG PUREFTPD WITH MYSQL AUTHENTICATION
Edit /etc/pure-ftpd/pure-ftpd.conf and make sure that the ChrootEveryone, MySQLConfigFile, and CreateHomeDir lines are enabled and look like this:
nano /etc/pure-ftpd/pure-ftpd.conf
[...]
ChrootEveryone			yes
[...]
MySQLConfigFile		    /etc/pure-ftpd/pureftpd-mysql.conf
[...]
CreateHomeDir       	yes
[...]
The ChrootEveryone setting will make PureFTPd chroot every virtual user in his home directory so he will not be able to browse directories and files outside his home directory. 
The CreateHomeDir line will make PureFTPd create a user's home directory when the user logs in and the home directory does not exist yet.
#
Then we edit /etc/pure-ftpd/pureftpd-mysql.conf. It should look like this:'
cp /etc/pure-ftpd/pureftpd-mysql.conf /etc/pure-ftpd/pureftpd-mysql.conf_orig
cat /dev/null > /etc/pure-ftpd/pureftpd-mysql.conf
nano /etc/pure-ftpd/pureftpd-mysql.conf
#
####################################
#/etc/pure-ftpd/pureftpd-mysql.conf#
####################################
#Unix socket
MYSQLSocket     /var/lib/mysql/mysql.sock     

#Not using TCP CONNECT:
#MYSQLServer    localhost
#MYSQLPort      3306
#
MYSQLDatabase   pureftpd
#
#MYSQLUser       nginx
#MYSQLPassword   nginx
#
MYSQLUser       ftpuser
MYSQLPassword   ftpgroup
#
#MYSQLCrypt md5, cleartext, crypt() or password() - md5 is VERY RECOMMENDABLE uppon cleartext
MYSQLCrypt          md5
MYSQLGetPW          SELECT Password        FROM ftpd WHERE User="\L"    AND status="1" AND (ipaccess = "*" OR ipaccess LIKE "\R")      
MYSQLGetUID         SELECT Uid             FROM ftpd WHERE User="\L"    AND status="1" AND (ipaccess = "*" OR ipaccess LIKE "\R") 
MYSQLGetGID         SELECT Gid             FROM ftpd WHERE User="\L"    AND status="1" AND (ipaccess = "*" OR ipaccess LIKE "\R")
MYSQLGetDir         SELECT Dir             FROM ftpd WHERE User="\L"    AND status="1" AND (ipaccess = "*" OR ipaccess LIKE "\R")
MySQLGetBandwidthUL SELECT ULBandwidth     FROM ftpd WHERE User="\L"    AND status="1" AND (ipaccess = "*" OR ipaccess LIKE "\R")
MySQLGetBandwidthDL SELECT DLBandwidth     FROM ftpd WHERE User="\L"    AND status="1" AND (ipaccess = "*" OR ipaccess LIKE "\R")
MySQLGetQTASZ       SELECT QuotaSize       FROM ftpd WHERE User="\L"    AND status="1" AND (ipaccess = "*" OR ipaccess LIKE "\R")
MySQLGetQTAFS       SELECT QuotaFiles      FROM ftpd WHERE User="\L"    AND status="1" AND (ipaccess = "*" OR ipaccess LIKE "\R")
#
Make sure that you replace the string ftpdpass with the real password for the MySQL user pureftpd in the line MYSQLPassword! Please note that we use md5 as MYSQLCrypt method, which means we will store the users' passwords as an MD5 string in the database which is far more secure than using plain text passwords!'
Now we create the system startup links for PureFTPd and start it:
#chkconfig --levels 235 pure-ftpd on
#/etc/init.d/pure-ftpd start 
#
To populate the database you can use the MySQL shell:
mysql -u root -p
USE pureftpd;
#
Now we create the user exampleuser with the status 1 (which means his ftp account is active), the password secret (which will be stored encrypted using MySQL's MD5 function), the UID and GID 2001 (use the userid and groupid of the user/group you created at the end of step two!), the home directory /home/www.example.com, an upload and download bandwidth of 100 KB/sec. (kilobytes per second), and a quota of 50 MB:'
INSERT INTO `ftpd` (`User`, `status`, `Password`, `Uid`, `Gid`, `Dir`, `ULBandwidth`, `DLBandwidth`, `comment`, `ipaccess`, `QuotaSize`, `QuotaFiles`) VALUES ('exampleuser', '1', MD5('secret'), '2001', '2001', '/home/www.example.com', '100', '100', '', '*', '50', '0');
quit;
#
Now open your FTP client program on your work station (something like WS_FTP or SmartFTP if you are on a Windows system or gFTP on a Linux desktop) and try to connect. As hostname you use server1.example.com (or the IP address of the system), the username is exampleuser, and the password is secret.
If you are able to connect - congratulations! If not, something went wrong.
Now, if you run
ls -l /home
you should see that the directory /home/www.example.com (exampleuser's home directory) has been created automatically, and it is owned by ftpuser and ftpgroup (the user/group we created at the end of step two):'
[root@server1 ~]# ls -l /home
total 4
drwxr-xr-x 2 ftpuser ftpgroup 4096 Mar  5 02:13 www.example.com
[root@server1 ~]# 
#
root@srv148 ~# cat /etc/pure-ftpd/pure-ftpd.conf 
############################################################
#/etc/pure-ftpd/pure-ftpd.conf
#Update: 8:18 01/02/2015
############################################################
ChrootEveryone              yes
BrokenClientsCompatibility  no
MaxClientsNumber            101
Daemonize                   yes
MaxClientsPerIP             80
VerboseLog                  yes
DisplayDotFiles             yes
AnonymousOnly               no
NoAnonymous                 yes
SyslogFacility              ftp
DontResolve                 yes
MaxIdleTime                 15
MySQLConfigFile             /etc/pure-ftpd/pureftpd-mysql.conf
PAMAuthentication               no
UnixAuthentication          no
LimitRecursion              10000 8
AnonymousCanCreateDirs      no
MaxLoad                     4
PassivePortRange                        60000 61000
AntiWarez                   yes
Umask                       133:022
MinUID                      500
UseFtpUsers                             no
AllowUserFXP                no
AllowAnonymousFXP           no
ProhibitDotFilesWrite       no
ProhibitDotFilesRead        no
AutoRename                  no
AnonymousCantUpload         yes
AltLog                          clf:/var/log/pureftpd.log
CreateHomeDir               yes
MaxDiskUsage                    99
CustomerProof                   yes
TLS                             2
IPV4Only                        yesroot@srv148 ~

#Anonymous FTP ACCT: [CANCEL if you don't want to use Anonymous acct]
(If you want to use /var/ftp instead, replace /home/ftp with /var/ftp in the above commands.) 
Anonymous users will be able to log in, and they will be allowed to download files from /home/ftp, but uploads will be limited to /home/ftp/incoming (and once a file is uploaded into /home/ftp/incoming, it cannot be read nor downloaded from there; the server admin has to move it into /home/ftp first to make it available to others).
Now we have to configure PureFTPd for anonymous ftp. Open /etc/pure-ftpd/pure-ftpd.conf and make sure that you have the following settings in it:
#vi /etc/pure-ftpd/pure-ftpd.conf 
[...]
NoAnonymous                 no
[...]
AntiWarez                   no
[...]
AnonymousBandwidth            8
[...]
AnonymousCantUpload         no
[...]	 
(The AnonymousBandwidth setting is optional - it allows you to limit upload and download bandwidths for anonymous users. 8 means 8 KB/sec. Use any value you like, or comment out the line if you don't want to limit bandwidths.) '
Finally, we restart PureFTPd:
#/etc/init.d/pure-ftpd restart 
#####################################
4/CONFIG PUREFTPD WITH TLS/SSL ENCRYPTION
#How To Configure PureFTPd To Accept TLS Sessions
#nano /etc/pure-ftpd/pure-ftpd.conf
	###TLS
	TLS                      	2
#
Creating The SSL Certificate For TLS
In order to use TLS, we must create an SSL certificate. I create it in /etc/ssl/private/, therefore I create that directory first:
#mkdir -p /etc/ssl/private/
Afterwards, we can generate the SSL certificate as follows:
#openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
#
Change the permissions of the SSL certificate: 
chmod 600 /etc/ssl/private/pure-ftpd.pem
Finally restart PureFTPd:
[root@srv122 ~]# /etc/init.d/pure-ftpd restart
That's it. You can now try to connect using your FTP client; however, you should configure your FTP client to use TLS - see the next chapter how to do this with FileZilla.'

######################################################
5/CONFIG FTP CLIENT (FILEZILLA) CONNECT TO FTP SERVER
In order to use FTP with TLS, you need an FTP client that supports TLS, such as FileZilla. 
In FileZilla, open the Server Manager: 
	HOST: 192.168.0.100
	PORT: 21
	PROTOCOL: FTP - Fule Transfer Protocol
	Encryption: Require explicit FTP over TLS/SSL
	Logon Type: Account
	User: exampleuser
	Password:secret
	Account:exampleuser
Click [Connect] to connect to FTP SERVER.

DONE FOR ALL

##################################
6/CONTACT
[Skype]: tinhcx
[Email]: tinhcx@gmail.com
System Administrator for 7 years