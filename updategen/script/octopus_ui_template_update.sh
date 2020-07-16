#!/bin/bash
set -e

workdir=$1
tag=$2

tmpdirlist=($workdir/tmp-ui/rbac $workdir/tmp-ui/tmprbac $workdir/tmp-ui/crds $workdir/tmp-ui/daemonset $workdir/tmp-ui/deployment $workdir/tmp-ui/service $workdir/tmp-ui/template)

for dir in ${tmpdirlist[*]}
do
if [ -d $dir ];then
rm -r $dir
else
mkdir -p $dir
fi
done 

sed -i "/^\s\{2\}tag:/{s/.*/  tag: $tag/}" ../charts/edge-ui/values.yaml 

awk -F'\n' -vRS='---\n' '
    {
       for(i=0;i<NF;i++){
           if($i~/^kind:/){
               split($i,a,":");
               gsub(" ","",a[2]);
               if (a[2]=="Role"){
                   print $0 > "'"$workdir"'/tmp-ui/rbac/role.yaml"
               }else if(a[2]=="RoleBinding"){
                   print $0 > "'"$workdir"'/tmp-ui/rbac/rolebing.yaml"
               }else if(a[2]=="ClusterRole"){
                   print $0 > "'"$workdir"'/tmp-ui/rbac/clusterrole.yaml"
               }else if(a[2]=="ClusterRoleBinding"){
                   print $0 > "'"$workdir"'/tmp-ui/rbac/clusterrolebing.yaml"
               }else if(a[2]=="ServiceAccount"){
                   print $0 > "'"$workdir"'/tmp-ui/rbac/serviceaccount.yaml"
               }else if(a[2]=="Service"){
                   print "---\n" >> "'"$workdir"'/tmp-ui/service/service.yaml";
                   print $0 >> "'"$workdir"'/tmp-ui/service/service.yaml";
               }else if(a[2]=="Deployment"){
                   print $0 > "'"$workdir"'/tmp-ui/deployment/deployment.yaml"
               }
            }
       }
    }
' $workdir/ui_all.yaml


for file in $workdir/tmp-ui/rbac/*
do
sed -e "/name: octopus-ui/{s/.*/  name: {{ template "edge-ui.fullname" . }}/}" ${file} > $workdir/tmp-ui/tmprbac/${file##*/}
sed -i "/labels:/{n;N;s/.*/    {{- include "edge-ui.labels" . | nindent 4 }}\n\
  {{- with .Values.serviceAccount.annotations }}/}"  $workdir/tmp-ui/tmprbac/${file##*/}
sed -i "/namespace:/{s/.*/  namespace: {{ .Values.apiNamespace }}/}" $workdir/tmp-ui/tmprbac/${file##*/}

if [ ${file##*/} == "clusterrolebing.yaml" ];then
sed -i "/name: octopus-ui-rolebinding/{s/.*/  name: {{ template "edge-ui.fullname" . }}-rolebinding/}" $workdir/tmp-ui/tmprbac/${file##*/}
fi

cat $workdir/tmp-ui/tmprbac/${file##*/} >> $workdir/tmp-ui/tmprbac/rbac.yaml
sed -i '$a\---' $workdir/tmp-ui/tmprbac/rbac.yaml
done

cp $workdir/tmp-ui/tmprbac/rbac.yaml $workdir/tmp-ui/template/rbac.yaml

for file in $workdir/tmp-ui/service/*
do
sed -e "/name: octopus-ui/{s/.*/  name: {{ template "edge-ui.fullname" . }}/}" ${file} > $workdir/tmp-ui/template/${file##*/}
sed -i "/labels:/{n;N;s/.*/    {{- include "edge-ui.labels" . | nindent 4 }}\n\
  {{- with .Values.serviceAccount.annotations }}/}"  $workdir/tmp-ui/template/${file##*/}
sed -i "/namespace:/{s/.*/  namespace: {{ .Values.apiNamespace }}/}" $workdir/tmp-ui/template/${file##*/}
sed -i "/^\s\{2\}type:/{s/.*/  type: {{ .Values.service.type }}/}" $workdir/tmp-ui/template/${file##*/}
sed -i "/port:/{s/:\{1\}\s.*/: {{ .Values.service.port }}/}" $workdir/tmp-ui/template/${file##*/}
sed -i "/selector/{n;N;s/.*/    {{- include "edge-ui.selectorLabels" . | nindent 4 }}/}" $workdir/tmp-ui/template/${file##*/}
done


for file in $workdir/tmp-ui/deployment/*
do
sed -e "/name: octopus-ui/{s/.*/  name: {{ template "edge-ui.fullname" . }}/}" ${file} > $workdir/tmp-ui/template/${file##*/}
sed -i "/labels:/{n;N;s/.*/    {{- include "edge-ui.labels" . | nindent 4 }}/}"  $workdir/tmp-ui/template/${file##*/}
sed -i "/matchLabels:/{n;N;N;s/.*/      {{- include "edge-ui.selectorLabels" . | nindent 6 }}/}" $workdir/tmp-ui/template/${file##*/}
sed -e "/^\s\{6\}affinity:/,+9d" -e "/^\s\{4\}spec:/a\      {{- with .Values.affinity }}\n\
      affinity:\n\
        {{- toYaml . | nindent 8 }}\n\
      {{- end }}" -i $workdir/tmp-ui/template/${file##*/}
sed -e "/^\s\{4\}spec:/a\      {{- with .Values.tolerations }}\n\
      tolerations:\n\
        {{- toYaml . | nindent 8 }}\n\
      {{- end }}" -i $workdir/tmp-ui/template/${file##*/}
sed -i "/image: cnrancher\/octopus-api-server/{s/.*/        image: {{ .Values.image.repository }}:{{ .Values.image.tag }}/}" $workdir/tmp-ui/template/${file##*/}
sed -i "/imagePullPolicy:/{s/.*/        imagePullPolicy: {{ .Values.image.pullPolicy }}/}" $workdir/tmp-ui/template/${file##*/}
sed -i "/image:/a\        resources:\n\
          {{- toYaml .Values.resources | nindent 12 }}" $workdir/tmp-ui/template/${file##*/}
done