#!/bin/bash
set -e 


workdir=$1
name=$2
tag=$3

tmpdir=$workdir/tmp-$name-adaptor

if [ -d $tmpdir ];then
rm -r $tmpdir
fi

mkdir -p $tmpdir
cp  -r initemplate/adaptor/*  $tmpdir
mkdir $tmpdir/crds


replace_dir(){
 adaptorname=$2
 echo ${adaptorname}
 adaptorresources="devices"
 if [ ${adaptorname} == "ble" ];then
    adaptorresources="bluetooth${adaptorresources}"
 else
    adaptorresources=${adaptorname}${adaptorresources}
 fi
 for file in `ls $1` 
 do
  if [ -d $1"/"$file ];then
  replace_dir $1"/"$file $adaptorname
  else
  echo $file
  sed -i "s/%generatorname%/${adaptorname}/g" $1"/"$file
  sed -i "s/%generatorresources%/${adaptorresources}/g" $1"/"$file
  fi
 done
}

replace_dir $tmpdir $name


yamlfile=${workdir}/${name}_all_in_one.yaml

awk -F"\n" -vRS="---\n" '
    {
       for(i=0;i<NF;i++){
           if($i~/^kind:/){
               split($i,a,":");
               gsub(" ","",a[2]);
               if (a[2]=="CustomResourceDefinition"){
                   print $0 > "'"$tmpdir"'/crds/'"$name"'.yaml"
               }
            }
       }}' $yamlfile

for((i=0;i<7;i++));
do 
sed -i '$d' $tmpdir/crds/$name.yaml;
done

sed -i "/creationTimestamp: null/d" $tmpdir/crds/$name.yaml