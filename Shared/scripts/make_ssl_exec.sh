#!/bin/env  bash
#
#  perl + db + ssl  + crypto
#
 
tolower()
{
local char="$*"

out=$(echo $char | tr [:upper:] [:lower:])
local retval=$?
echo "$out"
unset out
unset char
return $retval
}


XMLROOT=$(xml2-config  --prefix)
if [ -z $XMLROOT   ]
then
echo " libxml2 libraries must be installed on building host "
exit
fi  
 
XMLLIB_SO="$XMLROOT/lib/libxml2.so.2"
XMLLIB_A="$XMLROOT/lib/libxml2.a"
SSL_SO=/lib/libssl.so.4
SSL_A=/usr/lib/libssl.a
LIBCRYPTO_A=/usr/lib/libcrypto.a
LIBCRYPTO_SO=/lib/libcrypto.so.4


MODULE=$1

if ( [ ! -e "../lib/perfSONAR_PS/Services/MA/$MODULE.pm" ] || [ !  -e "../lib/perfSONAR_PS/Services/MP/$MODULE.pm" ] )
then
echo " Usage: make_exec.sh <service module name  - for example PingER> "
echo "        for service XXX next modules must exist: ../lib/perfSONAR_PS/Services/M[PA]/XXX.pm "
exit
fi
 

EXECNAME=$(tolower $MODULE) 
echo "Building executable ps-$EXECNAME  for $MODULE MA and MP"
 
COM="pp -I ../lib/ -M DBD::mysql -M  Sleepycat::DbXml  -M DBD::SQLite -M perfSONAR_PS::Services::LS  \
 -M perfSONAR_PS::Services::Echo -M  perfSONAR_PS::Request \
 -M perfSONAR_PS::RequestHandler  -M perfSONAR_PS::DB::RRD \
 -M perfSONAR_PS::DB::File  -M perfSONAR_PS::DB::XMLDB \
 -M perfSONAR_PS::DB::SQL -M perfSONAR_PS::DB::SQL::PingER \
 -M fields -M DateTime::Locale::en  \
 -M perfSONAR_PS::Services::MP::$MODULE  \
 -M perfSONAR_PS::Services::MA::$MODULE \
 -l  $XMLLIB_A  \
 -l  $XMLLIB_SO  \
 -l  $SSL_SO  \
 -l  $SSL_A  \
 -l  $LIBCRYPTO_A  \
 -l  $LIBCRYPTO_SO  \
 -o ps-$EXECNAME  ../perfsonar-daemon.pl"

echo -e " Building ... \n  $COM  \n "
$COM
