#!/usr/bin/env bash

#script to backup chef using https://github.com/mdxp/knife-backup to S3 using s3cmd
#run from cron with something like /opt/chef-backups/backup-chef.sh > /var/log/chef_backup 2>&1

DATESTAMP=`date +"%Y%b%d-%H%M%S"`
ARCHIVENAME="chef-backup-$DATESTAMP.tar.gz"
ROOTDIR="/opt/chef-backups"
ARCHIVEDIR="archives"
EXPORTDIR="chef-files"
BUCKET="s3://cpf-chef-backups/"
DESTEMAIL="admin@foo.com"
HOSTNAME=`hostname -f`


function check_status {

        status=$?
        name=$1
        if [ "$status" != "0" ]; then
                echo "ERROR:  running $name"
                echo "Error running $name on $HOSTNAME" | mail -s "Chef Backup Error" "$DESTEMAIL"
                exit 1
        fi
}

echo "Starting chef backup"
date
echo ""

#cd to the chef bacup dir that has has a chef config (in .chef)
cd $ROOTDIR/
check_status "cd to chef directory"

#run the knife command to export the files to the backup dir
knife backup export -D $ROOTDIR/$EXPORTDIR/
check_status "run knife backup"

#remove old archives
rm -r $ROOTDIR/$ARCHIVEDIR/*
check_status "clean up old archives"

#make the archive to upload to s3
tar -czf $ROOTDIR/$ARCHIVEDIR/$ARCHIVENAME $ROOTDIR/$EXPORTDIR
check_status "create backup archive"

#upload files
s3cmd put $ROOTDIR/$ARCHIVEDIR/$ARCHIVENAME $BUCKET
check_status "upload archive to s3"

echo ""
echo "Finished chef backup"
date

exit 0
