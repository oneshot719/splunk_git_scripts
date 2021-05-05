#!/bin/bash

###############
#variables
###############
export scriptsdir="/scripts"
export splunkbackups="$scriptsdir/splunkbackups"
export date=`date +"%m-%d-%Y_%H:%M:%S"`
##############################
#Pushing from DS01 to GIT
##############################
echo ""
echo "#--------------------------------#"
echo "Date: $date"
echo "Pushing latest config from DS01 to git..."

crontab -l >/$scriptsdir/crontab.txt
echo ""
echo "Removing current apps..."
rm -rf $splunkbackups
mkdir -p $splunkbackups
echo ""
echo "Copying latest splunk apps and deployment apps."
cp -r /opt/splunk/etc/apps $splunkbackups/apps
cp -r /opt/splunk/etc/deployment-apps $splunkbackups/deployment-apps
echo "Done copying splunk apps"
echo ""
sleep 5s
git -C $scriptsdir add --all
# git -C $scriptsdir commit -m "Crontab pushing DS01 recent edits"
git -c user.email=ds01@localhost.local -c user.name='DS01' -C $scriptsdir commit -m "Crontab pushing DS01 recent edits"
git -c user.email=ds01@localhost.local -c user.name='DS01' -c http.sslVerify=false -C $scriptsdir push origin master

echo "Done"
exit
