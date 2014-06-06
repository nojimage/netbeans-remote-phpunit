#!/usr/bin/env bash
##
# Custom PHPUnit script for Remote test on NetBaeans 8.0
##

#echo $@ #uncomment to debug
#echo "colors: $1"
#echo "log-junit: $2 $3"
#echo "bootstrap: $4 $5"
## and
#echo "suite: $6"
#echo "run: $7"
## or
#echo "filter: $6 $7"
#echo "suite: $8"
#echo "run: $9"
## or
#echo "coverage-clover: $6 $7"
#echo "suite: $8"
#echo "run: $9"
## or
#echo "coverage-clover: $6 $7"
#echo "filter: $8 $9"
#echo "suite: ${10}"
#echo "run: ${11}"

#
# Change these settings to your env
#
REMOTE_PKEY=~/.vagrant.d/insecure_private_key
REMOTE_SERVER=vagrant@192.168.33.10
REMOTE_ROOT="/var/www/vhosts/example.com/htdocs"
REMOTE_PHPUNIT="${REMOTE_ROOT}/vendor/bin/phpunit"
REMOTE_SUITE_PATH="${REMOTE_ROOT}/tests"
XDEBUG_CONFIG="idekey=netbeans-xdebug"

###
LOCAL_ROOT=$(cd "$(dirname "$(dirname "$0")")" && pwd)
echo $LOCAL_ROOT
if [[ $6 = "--coverage-clover" && $8 = "--filter" ]] ; then
  LOCAL_SUITE=${10}
  REMOTE_RUN=${11}
elif [[ $6 = "--filter" ||  $6 = "--coverage-clover" ]] ; then
  LOCAL_SUITE=$8
  REMOTE_RUN=$9
else
  LOCAL_SUITE=$6
  REMOTE_RUN=$7
fi

REMOTE_BOOTSTRAP=$5
REMOTE_BOOTSTRAP=${REMOTE_ROOT}${REMOTE_BOOTSTRAP/$LOCAL_ROOT/}

REMOTE_RUN=${REMOTE_RUN/--run=/}
REMOTE_RUN=${REMOTE_ROOT}${REMOTE_RUN/$LOCAL_ROOT/}

REMOTE_JUNITLOG=$3
REMOTE_JUNITLOG=${REMOTE_JUNITLOG/\/var\//\/tmp\/}

if [[ $6 = "--coverage-clover" ]] ; then
  REMOTE_CLOVERLOG=$7
  REMOTE_CLOVERLOG=${REMOTE_CLOVERLOG/\/var\//\/tmp\/}
fi

REMOTE_SUITE=${REMOTE_SUITE_PATH}/${LOCAL_SUITE##*/}

# Debug output
#echo $REMOTE_BOOTSTRAP
#echo $REMOTE_RUN
#echo $REMOTE_JUNITLOG
#echo $REMOTE_SUITE

# Remove logfile
ssh -q -i $REMOTE_PKEY $REMOTE_SERVER "if [ -f $REMOTE_JUNITLOG ] ; then rm $REMOTE_JUNITLOG; fi"
if [[ $6 = "--coverage-clover" ]] ; then
  ssh -q -i $REMOTE_PKEY $REMOTE_SERVER "if [ -f $REMOTE_CLOVERLOG ] ; then rm $REMOTE_CLOVERLOG; fi"
fi

# Copy suite file
scp -q -i $REMOTE_PKEY "$LOCAL_SUITE" $REMOTE_SERVER:$REMOTE_SUITE

# rsync
#vagrant rsync

# Connect to your vagrant VM, cd to your test location and run phpunit with appropriate args
if [[ $6 = "--coverage-clover" && $8 = "--filter" ]] ; then
  # rerun failed and with coverage
  ssh -q -i $REMOTE_PKEY $REMOTE_SERVER "cd $REMOTE_ROOT; XDEBUG_CONFIG=$XDEBUG_CONFIG $REMOTE_PHPUNIT $1 $2 $REMOTE_JUNITLOG --bootstrap $REMOTE_BOOTSTRAP --coverage-clover $REMOTE_CLOVERLOG --filter \"$9\" $REMOTE_SUITE --run=$REMOTE_RUN"
elif [[ $6 = "--coverage-clover" ]] ; then
  # with coverage
  ssh -q -i $REMOTE_PKEY $REMOTE_SERVER "cd $REMOTE_ROOT; XDEBUG_CONFIG=$XDEBUG_CONFIG $REMOTE_PHPUNIT $1 $2 $REMOTE_JUNITLOG --bootstrap $REMOTE_BOOTSTRAP --coverage-clover $REMOTE_CLOVERLOG $REMOTE_SUITE --run=$REMOTE_RUN"
elif [[ $6 = "--filter" ]] ; then
  # rerun failed
  ssh -q -i $REMOTE_PKEY $REMOTE_SERVER "cd $REMOTE_ROOT; XDEBUG_CONFIG=$XDEBUG_CONFIG $REMOTE_PHPUNIT $1 $2 $REMOTE_JUNITLOG --bootstrap $REMOTE_BOOTSTRAP --filter \"$7\" $REMOTE_SUITE --run=$REMOTE_RUN"
else
  # (re)run [all] tests 
  ssh -q -i $REMOTE_PKEY $REMOTE_SERVER "cd $REMOTE_ROOT; XDEBUG_CONFIG=$XDEBUG_CONFIG $REMOTE_PHPUNIT $1 $2 $REMOTE_JUNITLOG --bootstrap $REMOTE_BOOTSTRAP $REMOTE_SUITE --run=$REMOTE_RUN"
fi

# Copy the test output back to your local machine, where NetBeans expects to find it
# might not work on mac. definitely won't work on win!
scp -q -i $REMOTE_PKEY $REMOTE_SERVER:$REMOTE_JUNITLOG "$3.tmp"
sed -e "s~$REMOTE_ROOT~$LOCAL_ROOT~g" "$3.tmp" > $3

if [[ $6 = "--coverage-clover" ]] ; then
  scp -q -i $REMOTE_PKEY $REMOTE_SERVER:"$REMOTE_CLOVERLOG" "$7.tmp"
  sed -e "s~$REMOTE_ROOT~$LOCAL_ROOT~g" "$7.tmp" > $7
fi

