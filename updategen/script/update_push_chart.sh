#!/bin/bash
set -e 

workdir=$1

# git clone https://github.com/cnrancher/octopus-chart.git

cp  $workdir/tmp/template/*  ../templates/
cp  $workdir/tmp/crds/*    ../crds/

cp  $workdir/tmp-ui/template/*  ../charts/octopus-ui/templates

for dir in $workdir/*
do

filetype=`echo ${dir##*/} | awk -F'-' '{print $3}'`
if [ "$filetype" == "adaptor" ];then
adaptorname=`echo ${dir##*/} | awk -F'-' '{print $2}'`
echo ../charts/$adaptorname-$filetype
echo $dir
cp -r $dir/  ../charts/$adaptorname-$filetype/
fi
done
