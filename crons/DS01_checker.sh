#!/bin/bash
export date=`date +"%m-%d-%Y_%H:%M:%S"`
#below is the token for using api vs ssh key, this is needed because HTTPS forced, not allowing ssh cloning.
export key=`cat /gitlab_api_key`
export clone_command="/scripts/gitscripts/DS01_clone_push.sh"

echo ""
echo "#--------------------------------#"
echo "Date: $date"
echo "Starting Script.."
echo ""


#############
# BASE REPO
#############


export gitpath="/scripts/gitclones/splunk/ds01/"

echo ""
echo "Checking to make sure paths exist and if not will re-clone everything..."
echo ""
export does_exist=`ls $gitpath | wc -l`
#checking to see if directory exists, if not then we will clone it down, if so we check for new merges.

if [ "$does_exist" -gt "2" ];then
  echo "Confirmed that there has already been a git clone and we can continue checking for updates...";
elif [ "$does_exist" -eq "0" ];then
  echo "Can not find existing directory for $gitpath, we will initiate a new clone on everything.";
  rm -rf $gitpath
  sh $clone_command && exit
else [ "$does_exist" -eq "1" ]
  echo "Should be more than 1 files or folders, if it's just 1 then we will cleanup and re pull...";
  rm -rf $gitpath
  sh $clone_command && exit
fi

echo "Checking base repository for new commits..."



# [ $(GIT_SSH_COMMAND="ssh -i $key" git -C $gitpath rev-parse HEAD) = $(GIT_SSH_COMMAND="ssh -i $key" git -C $gitpath ls-remote $(GIT_SSH_COMMAND="ssh -i $key" git -C $gitpath rev-parse --abbrev-ref @{u} | sed 's/\// /g') | cut -f1) ] && (echo "$(date) - up to date, nothing to do") || (echo "$(date) - not up to date, grabbing latest config" && sh $clone_command && exit)
# above is original command using ssh key for cloning
# below is adapted for using api token https cloning
[ $(git -c http.sslVerify=false -C $gitpath rev-parse HEAD) = $(git -c http.sslVerify=false -C $gitpath ls-remote $(git -c http.sslVerify=false -C $gitpath rev-parse --abbrev-ref @{u} | sed 's/\// /g') | cut -f1) ] && (echo "$(date) - up to date, nothing to do") || (echo "$(date) - not up to date, grabbing latest config" && sh $clone_command && exit)

echo "Done with DS01 base..."



echo "Script Done"
