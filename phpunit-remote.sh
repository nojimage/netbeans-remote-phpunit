#!/usr/bin/env bash
##
# Custom PHPUnit script for Remote test on NetBaeans 8.2
##

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

#echo $LOCAL_ROOT

## parse options
while [[ $# -gt 2 ]] ; do
  #echo ">> ${1} ${2}"
  case $1 in
    '--colors' )
      COLORS=1
      ;;
    '--log-junit' )
      JUNITLOG="$2"
      shift
      ;;
    '--log-json' )
      JSONLOG="$2"
      shift
      ;;
    '--bootstrap' )
      BOOTSTRAP="$2"
      shift
      ;;
    '--filter' )
      FILTER="$2"
      shift
      ;;
    '--coverage-clover' )
      COVERAGE="$2"
      shift
      ;;
  esac

  shift
done

SUITE=$1
RUN=$2
RUN=${RUN/--run=/}

REMOTE_BOOTSTRAP=${REMOTE_ROOT}${BOOTSTRAP/$LOCAL_ROOT/}
REMOTE_JUNITLOG=${JUNITLOG/\/var\//\/tmp\/}
REMOTE_JSONLOG=${JSONLOG/\/var\//\/tmp\/}
REMOTE_CLOVERLOG=${CLOVERLOG/\/var\//\/tmp\/}
REMOTE_SUITE=${REMOTE_SUITE_PATH}/${SUITE##*/}
REMOTE_FILTER=${FILTER}
REMOTE_RUN=${RUN//$LOCAL_ROOT/$REMOTE_ROOT}

# Debug output
#echo $COLORS
#echo $REMOTE_BOOTSTRAP
#echo $REMOTE_JUNITLOG
#echo $REMOTE_JSONLOG
#echo $REMOTE_FILTER
#echo $REMOTE_CLOVERLOG
#echo $REMOTE_SUITE
#echo $REMOTE_RUN

# Remove logfile
if [[ -n "$JUNITLOG" ]] ; then
  ssh -q -i "$REMOTE_PKEY" $REMOTE_SERVER "if [ -f $REMOTE_JUNITLOG ] ; then rm $REMOTE_JUNITLOG; fi"
fi
if [[ -n "$JSONLOG" ]] ; then
  ssh -q -i "$REMOTE_PKEY" $REMOTE_SERVER "if [ -f $REMOTE_JSONLOG ] ; then rm $REMOTE_JSONLOG; fi"
fi
if [[ -n "$COVERAGE" ]] ; then
  ssh -q -i $REMOTE_PKEY $REMOTE_SERVER "if [ -f $REMOTE_CLOVERLOG ] ; then rm $REMOTE_CLOVERLOG; fi"
fi

# Copy suite file
scp -q -i $REMOTE_PKEY "$SUITE" $REMOTE_SERVER:$REMOTE_SUITE

# rsync
#vagrant rsync

## Build test command
COMMAND="cd $REMOTE_ROOT; XDEBUG_CONFIG=${XDEBUG_CONFIG} $REMOTE_PHPUNIT"

if [[ -n "$COLORS" ]] ; then
  COMMAND="${COMMAND} --colors"
fi

if [[ -n "$JUNITLOG" ]] ; then
  COMMAND="${COMMAND} --log-junit ${REMOTE_JUNITLOG}"
fi

if [[ -n "$JSONLOG" ]] ; then
  COMMAND="${COMMAND} --log-json ${REMOTE_JSONLOG}"
fi

if [[ -n "$BOOTSTRAP" ]] ; then
  COMMAND="${COMMAND} --bootstrap ${REMOTE_BOOTSTRAP}"
fi

if [[ -n "$FILTER" ]] ; then
  COMMAND="${COMMAND} --filter '${REMOTE_FILTER}'"
fi

if [[ -n "$COVERAGE" ]] ; then
  COMMAND="${COMMAND} --coverage-clover ${REMOTE_COVERAGE}"
fi

COMMAND="${COMMAND} $REMOTE_SUITE \"--run=${REMOTE_RUN}\""

## Execute
#echo $COMMAND
ssh -q -i $REMOTE_PKEY $REMOTE_SERVER "$COMMAND"

# Copy the test output back to your local machine, where NetBeans expects to find it
# might not work on mac. definitely won't work on win!
if [[ -n "$JUNITLOG" ]] ; then
  scp -q -i "$REMOTE_PKEY" $REMOTE_SERVER:$REMOTE_JUNITLOG "$JUNITLOG.tmp"
  sed -e "s~$REMOTE_ROOT~$LOCAL_ROOT~g" "$JUNITLOG.tmp" > $JUNITLOG
fi

if [[ -n "$JSONLOG" ]] ; then
  scp -q -i "$REMOTE_PKEY" $REMOTE_SERVER:$REMOTE_JSONLOG "$JSONLOG.tmp"
  sed -e "s~$REMOTE_ROOT~$LOCAL_ROOT~g" "$JSONLOG.tmp" > $JSONLOG
fi

if [[ -n "$COVERAGE" ]] ; then
  scp -q -i $REMOTE_PKEY $REMOTE_SERVER:"$REMOTE_CLOVERLOG" "$COVERAGE.tmp"
  sed -e "s~$REMOTE_ROOT~$LOCAL_ROOT~g" "$COVERAGE.tmp" > $COVERAGE
fi
