#!/usr/bin/env bash

#echo $@ #uncomment to debug
#echo $1 $2 $3 $4 $5 $6 $7 $8 $9
#echo "colors: $1"
#echo "log-junit: $2 $3"
#echo "bootstrap: $4 $5"
#echo "suite: $6"
#echo "run: $7"
#echo "filter: $8 $9"

#
# Change these settings to your env
#
REMOTE_PKEY=~/.vagrant.d/insecure_private_key
REMOTE_SERVER=vagrant@192.168.33.10
REMOTE_ROOT="/var/www/vhosts/example.com/htdocs"
REMOTE_PHPUNIT="${REMOTE_ROOT}/vendor/bin/phpunit"
REMOTE_SUITE_PATH="${REMOTE_ROOT}/tests"

###
LOCAL_ROOT=$(dirname "$(dirname "$0")")
LOCAL_SUITE=$6

REMOTE_BOOTSTRAP=$5
REMOTE_BOOTSTRAP=${REMOTE_ROOT}${REMOTE_BOOTSTRAP/$LOCAL_ROOT/}

REMOTE_RUN=$7
REMOTE_RUN=${REMOTE_RUN/--run=/}
REMOTE_RUN=${REMOTE_ROOT}${REMOTE_RUN/$LOCAL_ROOT/}

REMOTE_JUNITLOG=$3
REMOTE_JUNITLOG=${REMOTE_JUNITLOG/\/var\//\/tmp\/}

REMOTE_SUITE=${REMOTE_SUITE_PATH}/${LOCAL_SUITE##*/}

# Debug output
#echo $REMOTE_BOOTSTRAP
#echo $REMOTE_RUN
#echo $REMOTE_JUNITLOG
#echo $REMOTE_SUITE

# Copy suite file
scp -i $REMOTE_PKEY "$6" $REMOTE_SERVER:$REMOTE_SUITE

# rsync
#vagrant rsync

# Connect to your vagrant VM, cd to your test location and run phpunit with appropriate args
if [[ $8 = "--filter" ]]
then
	#"rerun failed"
	ssh -i $REMOTE_PKEY $REMOTE_SERVER "cd $REMOTE_ROOT; $REMOTE_PHPUNIT $1 $2 $REMOTE_JUNITLOG --bootstrap $REMOTE_BOOTSTRAP $REMOTE_SUITE --run=$REMOTE_RUN --filter \"$9\""
else
	#"(re)run [all] tests"
	ssh -i $REMOTE_PKEY $REMOTE_SERVER "cd $REMOTE_ROOT; $REMOTE_PHPUNIT $1 $2 $REMOTE_JUNITLOG --bootstrap $REMOTE_BOOTSTRAP $REMOTE_SUITE --run=$REMOTE_RUN"
fi

# Copy the test output back to your local machine, where NetBeans expects to find it
# might not work on mac. definitely won't work on win!
scp -i $REMOTE_PKEY $REMOTE_SERVER:$REMOTE_JUNITLOG $3
