#/bin/bash
#
#
#
export ANSIBLE_SERVERS=`date +%a_%H%M`
export ANSIBLE_SERVERS=`echo $ANSIBLE_SERVERS | tr '[:lower:]' '[:upper:]'`
#echo $ANSIBLE_SERVERS

export DAY_NAME=`date +%a`
#echo $DAY_NAME

export DAY=`date +%d`
#echo $DAY

export MONTH=`date +%m`
#echo $MONTH

export YEAR=`date +%Y`

export ANSIBLE_HOSTS=/etc/ansible/hosts
export PLAYBOOKS_DIR=/home/deploy/playbooks
export LOGS_DIR=/home/deploy/logs
export ERRORS_DIR=/home/deploy/errors

case $DAY_NAME in
Sun) case $DAY in
       05|06|07|08|09|10|11) export WEEK=1ST; ;;
       12|13|14|15|16|17|18) export WEEK=2ND; ;;
       19|20|21|22|23|24|25) export WEEK=3RD; ;;
       26|27|28|29|30|31)    export WEEK=4TH; ;;
       *)                    export WEEK=NOPATCH; ;;
     esac; ;;
Sat) case $DAY in
       04|05|06|07|08|09|10) export WEEK=1ST; ;;
       11|12|13|14|15|16|17) export WEEK=2ND; ;;
       18|19|20|21|22|23|24) export WEEK=3RD; ;;
       25|26|27|28|29|30|31) export WEEK=4TH; ;;
       *)                    export WEEK=NOPATCH; ;;
     esac; ;;
*)   case $DAY in
       01|02|03|04|05|06|07) export WEEK=1ST; ;;
       08|09|10|11|12|13|14) export WEEK=2ND; ;;
       15|16|17|18|19|20|21) export WEEK=3RD; ;;
       22|23|24|25|26|27|28) export WEEK=4TH; ;;
       *) export WEEK=5TH; ;;
     esac; ;;
esac;

export ANSIBLE_SERVERS="$WEEK"_"$ANSIBLE_SERVERS"

case "$MONTH" in
01|04|07|10)  export TYPE=full; ;;
*) export TYPE=security; ;;
esac;

#echo $TYPE

if [ $# == 2 ];
  then
    echo "Server Group and Patch Type Passed as Arguments"
    echo "Ignore errors from fatal_search.py"
   ANSIBLE_SERVERS=$1
   TYPE=$2
else
   echo "Invalid arguments passed, we will use date generated server list and patch type"
   echo $ANSIBLE_SERVERS
   echo $TYPE
fi

export SERVERS_TO_PATCH=`grep "\[$ANSIBLE_SERVERS\]" $ANSIBLE_HOSTS | wc -l`

if [ $SERVERS_TO_PATCH == 1 ];
 then
    ansible-playbook -v $PLAYBOOKS_DIR/yum_update_"$TYPE"_reboot.yml --extra-vars "servers=$ANSIBLE_SERVERS" > $LOGS_DIR/yum_update_"$TYPE"_reboot_ansible_$ANSIBLE_SERVERS.log

    cat $LOGS_DIR/yum_update_"$TYPE"_reboot_ansible_$ANSIBLE_SERVERS.log | mailx -s "Ansible Patching $ANSIBLE_SERVERS" j-wiedemann@northwestern.edu pips-os@pim.northwestern.edu

    /home/deploy/cron/fatal_search.py $LOGS_DIR/yum_update_"$TYPE"_reboot_ansible_$ANSIBLE_SERVERS.log

    echo $ERRORS_DIR/"$YEAR"_"$MONTH"_"$DAY"/yum_update_"$TYPE"_reboot_ansible_"$ANSIBLE_SERVERS".error
    echo


    if [[ -s $ERRORS_DIR/"$YEAR"_"$MONTH"_"$DAY"/yum_update_"$TYPE"_reboot_ansible_"$ANSIBLE_SERVERS".error ]] ; then
        echo "There are errors"
        cat $ERRORS_DIR/$YEAR"_"$MONTH"_"$DAY/yum_update_"$TYPE"_reboot_ansible_"$ANSIBLE_SERVERS".error |mailx -s "Ansible Patching $ANSIBLE_SERVERS Errors" j-wiedemann@northwestern.edu pips-os@pim.northwestern.edu
        else
        echo "No Errors"
    fi
else
   echo "No ANSIBLE Group $ANSIBLE_SERVERS, nothing to patch"
   exit 1
fi
exit 0