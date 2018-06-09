INSERT INTO tbl_command VALUES 
(1,'notify-host-by-email','/usr/bin/printf \"%b\" \"***** Nagios *****\\n\\nNotification Type: $NOTIFICATIONTYPE$\\nHost: $HOSTNAME$\\nState: $HOSTSTATE$\\nAddress: $HOSTADDRESS$\\nInfo: $HOSTOUTPUT$\\n\\nDate/Time: $LONGDATETIME$\\n\" | /usr/bin/mail -s \"** $NOTIFICATIONTYPE$ Host Alert: $HOSTNAME$ is $HOSTSTATE$ **\" $CONTACTEMAIL$',2,'1','1','',0,1),
(2,'notify-service-by-email','/usr/bin/printf \"%b\" \"***** Nagios *****\\n\\nNotification Type: $NOTIFICATIONTYPE$\\n\\nService: $SERVICEDESC$\\nHost: $HOSTALIAS$\\nAddress: $HOSTADDRESS$\\nState: $SERVICESTATE$\\n\\nDate/Time: $LONGDATETIME$\\n\\nAdditional Info:\\n\\n$SERVICEOUTPUT$\\n\" | /usr/bin/mail -s \"** $NOTIFICATIONTYPE$ Service Alert: $HOSTALIAS$/$SERVICEDESC$ is $SERVICESTATE$ **\" $CONTACTEMAIL$',2,'1','1','',0,1),
(3,'check-host-alive','$USER1$/check_ping -H $HOSTADDRESS$ -w 3000.0,80% -c 5000.0,100% -p 5',1,'1','1','',0,1),
(4,'check_local_disk','$USER1$/check_disk -w $ARG1$ -c $ARG2$ -p $ARG3$',1,'1','1','',0,1),
(5,'check_local_load','$USER1$/check_load -w $ARG1$ -c $ARG2$',1,'1','1','',0,1),
(6,'check_local_procs','$USER1$/check_procs -w $ARG1$ -c $ARG2$ -s $ARG3$',1,'1','1','',0,1),
(7,'check_local_users','$USER1$/check_users -w $ARG1$ -c $ARG2$',1,'1','1','',0,1),
(8,'check_local_swap','$USER1$/check_swap -w $ARG1$ -c $ARG2$',1,'1','1','',0,1),
(9,'check_local_mrtgtraf','$USER1$/check_mrtgtraf -F $ARG1$ -a $ARG2$ -w $ARG3$ -c $ARG4$ -e $ARG5$',1,'1','1','',0,1),
(10,'check_ftp','$USER1$/check_ftp -H $HOSTADDRESS$ $ARG1$',1,'1','1','',0,1),
(11,'check_hpjd','$USER1$/check_hpjd -H $HOSTADDRESS$ $ARG1$',1,'1','1','',0,1),
(12,'check_snmp','$USER1$/check_snmp -H $HOSTADDRESS$ $ARG1$',1,'1','1','',0,1),
(13,'check_http','$USER1$/check_http -I $HOSTADDRESS$ $ARG1$',1,'1','1','',0,1),
(14,'check_ssh','$USER1$/check_ssh $ARG1$ $HOSTADDRESS$',1,'1','1','',0,1),
(15,'check_dhcp','$USER1$/check_dhcp $ARG1$',1,'1','1','',0,1),
(16,'check_ping','$USER1$/check_ping -H $HOSTADDRESS$ -w $ARG1$ -c $ARG2$ -p 5',1,'1','1','',0,1),
(17,'check_pop','$USER1$/check_pop -H $HOSTADDRESS$ $ARG1$',1,'1','1','',0,1),
(18,'check_imap','$USER1$/check_imap -H $HOSTADDRESS$ $ARG1$',1,'1','1','',0,1),
(19,'check_smtp','$USER1$/check_smtp -H $HOSTADDRESS$ $ARG1$',1,'1','1','',0,1),
(20,'check_tcp','$USER1$/check_tcp -H $HOSTADDRESS$ -p $ARG1$ $ARG2$',1,'1','1','',0,1),
(21,'check_udp','$USER1$/check_udp -H $HOSTADDRESS$ -p $ARG1$ $ARG2$',1,'1','1','',0,1),
(22,'check_nt','$USER1$/check_nt -H $HOSTADDRESS$ -p 12489 -v $ARG1$ $ARG2$',1,'1','1','',0,1),
(23,'process-host-perfdata','/usr/bin/printf \"%b\" \"$LASTHOSTCHECK$\\t$HOSTNAME$\\t$HOSTSTATE$\\t$HOSTATTEMPT$\\t$HOSTSTATETYPE$\\t$HOSTEXECUTIONTIME$\\t$HOSTOUTPUT$\\t$HOSTPERFDATA$\\n\" >> /opt/nagios/var/host-perfdata.out',2,'1','1','',0,1),
(24,'process-service-perfdata','/usr/bin/printf \"%b\" \"$LASTSERVICECHECK$\\t$HOSTNAME$\\t$SERVICEDESC$\\t$SERVICESTATE$\\t$SERVICEATTEMPT$\\t$SERVICESTATETYPE$\\t$SERVICEEXECUTIONTIME$\\t$SERVICELATENCY$\\t$SERVICEOUTPUT$\\t$SERVICEPERFDATA$\\n\" >> /opt/nagios/var/service-perfdata.out',2,'1','1','',0,1),
(25,'process-service-perfdata-file','/bin/mv /opt/pnp4nagios/var/service-perfdata /opt/pnp4nagios/var/spool/service-perfdata.$TIMET$',2,'1','1','',0,1),
(26,'process-host-perfdata-file','/bin/mv /opt/pnp4nagios/var/host-perfdata /opt/pnp4nagios/var/spool/host-perfdata.$TIMET$',2,'1','1','',0,1);


INSERT INTO tbl_contact VALUES (1,'nagiosadmin','Nagios Admin',0,2,NULL,2,2,1,1,'','',0,2,0,2,2,2,2,'root@localhost','','','','','','','','',0,1,2,'1','1','',0,1);
INSERT INTO tbl_contactgroup VALUES (1,'admins','Nagios Administrators',1,0,'1','1','',0,1);
INSERT INTO tbl_contacttemplate VALUES (1,'generic-contact','',0,2,NULL,2,2,0,1,'d,u,r,f,s','w,u,c,r,f,s',1,2,1,2,2,2,2,'','','','','','','','',0,0,2,'0','1','',0,1);
INSERT INTO tbl_host VALUES (1,'localhost','localhost','','127.0.0.1',0,2,NULL,0,2,'0',1,2,'',NULL,NULL,NULL,2,2,0,2,2,NULL,0,2,NULL,NULL,2,'',2,2,2,0,2,0,2,NULL,0,NULL,'',2,'','','','','','','','','','',0,'','1','1','',0,1);
INSERT INTO tbl_hostgroup VALUES (1,'servers','servers',1,0,'','','','1','1','',0,1);
INSERT INTO tbl_hosttemplate VALUES (1,'generic-host','',0,2,NULL,0,2,'3',0,2,'',3,5,1,2,2,0,2,2,NULL,0,2,NULL,NULL,2,'',2,2,2,0,2,1,2,60,1,NULL,'d,u,r',2,'','','','','','','','','','',0,'0','1','',0,1);
INSERT INTO tbl_lnkContactToContacttemplate VALUES (1,1,1,1);
INSERT INTO tbl_lnkContactgroupToContact VALUES (1,1,0);
INSERT INTO tbl_lnkContacttemplateToCommandHost VALUES (1,1,0);
INSERT INTO tbl_lnkContacttemplateToCommandService VALUES (1,2,0);
INSERT INTO tbl_lnkHostToHosttemplate VALUES (1,1,1,1);
INSERT INTO tbl_lnkHostgroupToHost VALUES (1,1,0);
INSERT INTO tbl_lnkHosttemplateToContactgroup VALUES (1,1,0);
INSERT INTO tbl_lnkServiceToHost VALUES (4,1,0),(7,1,0),(2,1,0),(1,1,0),(8,1,0),(3,1,0),(5,1,0);
INSERT INTO tbl_lnkServiceToServicetemplate VALUES (8,2,1,1),(7,2,1,1),(5,2,1,1),(4,2,1,1),(3,2,1,1),(2,2,1,1),(1,2,1,1);
INSERT INTO tbl_lnkServicetemplateToContactgroup VALUES (2,1,0);
INSERT INTO tbl_lnkTimeperiodToTimeperiodUse VALUES (5,4,0);
INSERT INTO tbl_service VALUES
(1,'localhost',1,2,0,2,'PING','',0,2,NULL,0,2,1,2,'16!100.0,20%!500.0,60%',2,'',NULL,NULL,NULL,2,2,0,2,2,2,NULL,0,2,NULL,NULL,2,'',2,2,2,NULL,NULL,0,'',2,0,2,0,2,'','','','','','',0,'','1','1','2018-06-09 23:12:42',0,1,'371481bf6b0d725f572e4d97bd4e9554517ff7c7'),
(2,'localhost',1,2,0,2,'Root Partition','',0,2,NULL,0,2,1,2,'4!20%!10%!/',2,'',NULL,NULL,NULL,2,2,0,2,2,2,NULL,0,2,NULL,NULL,2,'',2,2,2,NULL,NULL,0,'',2,0,2,0,2,'','','','','','',0,'','1','1','2018-06-09 23:12:42',0,1,'18a4fc9848cdec454e33ee61c0d56b7f6e2f2171'),
(3,'localhost',1,2,0,2,'Current Users','',0,2,NULL,0,2,1,2,'7!20!50',2,'',NULL,NULL,NULL,2,2,0,2,2,2,NULL,0,2,NULL,NULL,2,'',2,2,2,NULL,NULL,0,'',2,0,2,0,2,'','','','','','',0,'','1','1','2018-06-09 23:12:42',0,1,'062fbd69060679aa6152d4152dc66a7123a7f4dc'),
(4,'localhost',1,2,0,2,'Total Processes','',0,2,NULL,0,2,1,2,'6!250!400!RSZDT',2,'',NULL,NULL,NULL,2,2,0,2,2,2,NULL,0,2,NULL,NULL,2,'',2,2,2,NULL,NULL,0,'',2,0,2,0,2,'','','','','','',0,'','1','1','2018-06-09 23:12:42',0,1,'fc250fa70d17061759af179d1852fc892f99a86f'),
(5,'localhost',1,2,0,2,'Current Load','',0,2,NULL,0,2,1,2,'5!5.0,4.0,3.0!10.0,6.0,4.0',2,'',NULL,NULL,NULL,2,2,0,2,2,2,NULL,0,2,NULL,NULL,2,'',2,2,2,NULL,NULL,0,'',2,0,2,0,2,'','','','','','',0,'','1','1','2018-06-09 23:12:42',0,1,'e327d173d7603018ef475966991f33f684789958'),
(7,'localhost',1,2,0,2,'SSH','',0,2,NULL,0,2,1,2,'14',2,'',NULL,NULL,NULL,2,2,0,2,2,2,NULL,0,2,NULL,NULL,2,'',2,2,2,NULL,NULL,0,'',2,0,2,0,2,'','','','','','',0,'','1','1','2018-06-09 23:12:42',0,1,'6722b40f8c9f4ac61890d28b5d09a2445962c552'),
(8,'localhost',1,2,0,2,'HTTP','',0,2,NULL,0,2,1,2,'13',2,'',NULL,NULL,NULL,2,2,0,2,2,2,NULL,0,2,NULL,NULL,2,'',2,2,2,NULL,NULL,0,'',2,0,2,0,2,'','','','','','',0,'','1','1','2018-06-09 23:12:42',0,1,'4bb45772cf3540dc6d72b91ed38716689354b29a');
INSERT INTO tbl_servicetemplate VALUES (2,'generic-service',0,2,0,2,'','',0,2,NULL,0,2,0,2,'',0,'',3,10,2,1,1,2,1,1,0,NULL,0,1,NULL,NULL,1,'',1,1,1,60,NULL,0,'w,u,c,r',1,0,2,1,2,'','','','','','',0,'0','1','2018-06-09 22:37:31',0,1,'');
INSERT INTO tbl_timedefinition VALUES
(1,1,'sunday','00:00-24:00','0000-00-00 00:00:00'),
(2,1,'monday','00:00-24:00','0000-00-00 00:00:00'),
(3,1,'tuesday','00:00-24:00','0000-00-00 00:00:00'),
(4,1,'wednesday','00:00-24:00','0000-00-00 00:00:00'),
(5,1,'thursday','00:00-24:00','0000-00-00 00:00:00'),
(6,1,'friday','00:00-24:00','0000-00-00 00:00:00'),
(7,1,'saturday','00:00-24:00','0000-00-00 00:00:00'),
(8,2,'monday','09:00-17:00','0000-00-00 00:00:00'),
(9,2,'tuesday','09:00-17:00','0000-00-00 00:00:00'),
(10,2,'wednesday','09:00-17:00','0000-00-00 00:00:00'),
(11,2,'thursday','09:00-17:00','0000-00-00 00:00:00'),
(12,2,'friday','09:00-17:00','0000-00-00 00:00:00'),
(13,4,'january 1','00:00-00:00','0000-00-00 00:00:00'),
(14,4,'monday -1 may','00:00-00:00','0000-00-00 00:00:00'),
(15,4,'july 4','00:00-00:00','0000-00-00 00:00:00'),
(16,4,'monday 1 september','00:00-00:00','0000-00-00 00:00:00'),
(17,4,'thursday 4 november','00:00-00:00','0000-00-00 00:00:00'),
(18,4,'december 25','00:00-00:00','0000-00-00 00:00:00'),
(19,5,'sunday','00:00-24:00','0000-00-00 00:00:00'),
(20,5,'monday','00:00-24:00','0000-00-00 00:00:00'),
(21,5,'tuesday','00:00-24:00','0000-00-00 00:00:00'),
(22,5,'wednesday','00:00-24:00','0000-00-00 00:00:00'),
(23,5,'thursday','00:00-24:00','0000-00-00 00:00:00'),
(24,5,'friday','00:00-24:00','0000-00-00 00:00:00'),
(25,5,'saturday','00:00-24:00','0000-00-00 00:00:00');

INSERT INTO tbl_timeperiod VALUES
(1,'24x7','24 Hours A Day, 7 Days A Week',0,0,'','1','1','2018-06-09 22:37:31',0,1),
(2,'workhours','Normal Work Hours',0,0,'','1','1','2018-06-09 22:37:31',0,1),
(3,'none','No Time Is A Good Time',0,0,'','1','1','2018-06-09 22:37:31',0,1),
(4,'us-holidays','U.S. Holidays',0,0,'us-holidays','1','1','2018-06-09 22:37:31',0,1),
(5,'24x7_sans_holidays','24x7 Sans Holidays',0,1,'','1','1','2018-06-09 22:37:31',0,1);
