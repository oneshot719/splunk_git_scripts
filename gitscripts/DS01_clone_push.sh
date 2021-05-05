#!/bin/bash


curl -X POST -H 'Content-type: application/json' --data '{"text":":wavy_dash: New GitLab merge detected in watched repositories, pushing latest code to DS01... :wavy_dash:"}' https://hooks.slack.com/services/*OMITTED*

#exit

###############
#  variables  #
###############

export APP_COUNT="40"
# optionally increase the above number for each app we bring on to verify copies worked well
# we use logic greater than below so that we don't need to edit this script as often.

export key=`cat /gitlab_api_key`
export repo_DS01_base="https://splunk_ds01_api:$key@*OMITTED/splunk/ds01.git"
# git -c http.sslVerify=false clone $repo_DS01_base
export githome="/scripts/gitclones/splunk"
mkdir -p $githome
export master_gitpath="$githome"
export temp_gitpath="$githome/tmp"
mkdir -p $temp_gitpath
export reponame="ds01"
export splunk_install_directory="/opt"
export appsdir="$splunk_install_directory/splunk/etc/apps"
export dsappsdir="$splunk_install_directory/splunk/etc/deployment-apps"
export serverclassappname="VSOC_Serverclass"
export serverclassapp="$appsdir/$serverclassappname"


###############
#Check if running as non-root
###############
export user=`whoami`
export name="splunk"
echo user="$user"
echo name="$name"
if [[ "$user" == "$name" ]];then
  echo "We're running as $name, which is good continuing..." && break;
else
  echo "We are running as a $user , please run properly under $name" && curl -X POST -H 'Content-type: application/json' --data '{"text":":wavy_dash: :bangbang: GIT SCRIPT ERROR, not running under proper user. Talk to Matt Lucas to fix ... :bangbang: :wavy_dash:"}' https://hooks.slack.com/services/*OMITTED* && exit;

fi
unset user
unset name
echo ""

cd ~

echo "Removing old clones..."
rm -rf $master_gitpath/$reponame


##################
#DS01 Base Master Branch
##################

echo "Cloning latest DS01 base git merge..."

#below is command for SSH cloning
# GIT_SSH_COMMAND="ssh -i $key" git clone -b master --single-branch $repo_DS01_base $master_gitpath/$reponame

#below is command for api token cloning
git -c http.sslVerify=false clone -b master --single-branch  "$repo_DS01_base" $master_gitpath/$reponame



##################
#CHOWN
##################


chmod -R 755 $master_gitpath/$reponame
chown -R splunk:splunk $master_gitpath/$reponame

#ADD IN CHECK TO MAKE SURE CLONE WORKED PROPERLY
echo "Checking to make sure clone worked..."
export gitworked=`cat $master_gitpath/$reponame/apps/$serverclassappname/default/serverclass.conf | wc -l`

if [ "$gitworked" -gt "5" ];then
  echo "Git Clone worked"
else
  echo "Git Clone failed... Exiting Script" && curl -X POST -H 'Content-type: application/json' --data '{"text":":wavy_dash: :bangbang: GIT SCRIPT ERROR, ERROR detected during validation checks, code not pushed. Talk to Matt Lucas to fix ... :bangbang: :wavy_dash:"}' https://hooks.slack.com/services/*OMITTED* && exit
fi


# commands executing for DS01
echo "Removing Existing serverclass to overwrite what comes from GIT..."

echo "Stopping Splunk..."
#stopping because i need to properly reload the serverclass and some things don't get applied with a reload
$splunk_install_directory/splunk/bin/splunk stop

rm -rf $serverclassapp


#below is designed to escape alias for the proper -f flag. trust me it's better this way
/bin/cp -rf $master_gitpath/$reponame/apps/* $splunk_install_directory/splunk/etc/apps/

echo "Removing Existing deployment apps directory to overwrite what comes from GIT..."
rm -rf $dsappsdir/*
#below is designed to escape alias for the proper -f flag. trust me it's better this way
/bin/cp -rf $master_gitpath/$reponame/deployment-apps/* $dsappsdir/



# ADD IN CHECK TO MAKE SURE FILES EXIST ON DS DEPLOYMENT-APPS BEFORE STARTING
# IF YOU START THE DS WITHOUT ANY APPS, ALL THE APPS WILL BE DELETED FROM CLIENTS
# RAINING LITERAL HELL.

#######################
# LOGIC CHECK BASE APPS
#######################

echo "Checking to make sure copy worked..."
export app_count_GIT=`ls $master_gitpath/$reponame/deployment-apps/ | wc -l`
export app_count_DS=`ls $splunk_install_directory/splunk/etc/deployment-apps/ | wc -l`
# we subtract 1 because of things
# export app_count_DS=`expr $app_count_DS - 1` <-- not needed unless using ansible or other distributed shell

# We want to make sure that our local app count is at least over 5 as a hardcoded value to prevent the $APP_COUNT if accidentially set to 0 or null from allowing us to empty deploy
# this is a cover my ass essentially
if [ "$app_count_GIT" -gt "5" ];then
  echo "app_count_GIT is greater than 5, it is: $app_count_GIT"
else
  echo "app_count_GIT is NOT greater than 5, it is: $app_count_GIT... Exiting Script"  && curl -X POST -H 'Content-type: application/json' --data '{"text":":wavy_dash: :bangbang: GIT SCRIPT ERROR, ERROR detected during validation checks, code not pushed. Talk to Matt Lucas to fix ... :bangbang: :wavy_dash:"}' https://hooks.slack.com/services/*OMITTED* && exit
fi

# We want to make sure that our DS app count is at least over 5
if [ "$app_count_DS" -gt "5" ];then
  echo "app_count_DS is greater than 5, it is: $app_count_DS"
else
  echo "app_count_DS is NOT greater than 5, it is: $app_count_DS... Exiting Script" && curl -X POST -H 'Content-type: application/json' --data '{"text":":wavy_dash: :bangbang: GIT SCRIPT ERROR, ERROR detected during validation checks, code not pushed. Talk to Matt Lucas to fix ... :bangbang: :wavy_dash:"}' https://hooks.slack.com/services/*OMITTED* && exit
fi




###########################
# LOGIC CHECK COMPARE APPS
###########################

echo "Checking to make sure copy worked..."
export app_count_GIT=`ls $master_gitpath/$reponame/deployment-apps/ | wc -l`
export app_count_DS=`ls $splunk_install_directory/splunk/etc/deployment-apps/ | wc -l`
# we subtract 1 because of things
# export app_count_DS=`expr $app_count_DS - 1` <-- not needed unless using ansible or other distributed shell

# We want to make sure that our app counts from GIT and our app counts in deployment-apps also match our defined app count $APP_COUNT at the top of this script.
# if not match, then abort
if [ "$app_count_DS" -gt "$APP_COUNT" ];then
  echo "app_count_DS is: $app_count_DS AND boundary for APP_COUNT is: $APP_COUNT. WE PASS BOUNDARY CHECKS, allowing to progress script..."
  export splunk_command="restart"
  echo "Splunk command is: $splunk_command"

else
  echo "app_count_DS is: $app_count_DS AND boundary for APP_COUNT is: $APP_COUNT. ---- WE DO NOT MATCH--- ...... Exiting Script"  && curl -X POST -H 'Content-type: application/json' --data '{"text":":wavy_dash: :bangbang: GIT SCRIPT ERROR, ERROR detected during validation checks, code not pushed. Talk to Matt Lucas to fix ... :bangbang: :wavy_dash:"}' https://hooks.slack.com/services/*OMITTED* && exit
  export splunk_command="stop"
fi




echo "Lets get our chown on..."
chown -R splunk:splunk "$splunk_install_directory/splunk/etc/apps"
chmod -R 755 "$splunk_install_directory/splunk/etc/apps"
chown -R splunk:splunk "$splunk_install_directory/splunk/etc/deployment-apps"
chmod -R 755 "$splunk_install_directory/splunk/etc/deployment-apps"


echo "$splunk_command Splunk ..."
$splunk_install_directory/splunk/bin/splunk $splunk_command
curl -X POST -H 'Content-type: application/json' --data '{"text":":wavy_dash: DS01 Code has been pushed and restarted successfully :wavy_dash:"}' https://hooks.slack.com/services/*OMITTED*
echo "All Done"


