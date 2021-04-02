#!/bin/bash
set -e

workdir=$1

tmpdirlist=($workdir/tmp/rbac $workdir/tmp/tmprbac $workdir/tmp/crds $workdir/tmp/daemonset $workdir/tmp/deployment $workdir/tmp/service $workdir/tmp/template)

for dir in ${tmpdirlist[*]}
do
if [ -d $dir ];then
rm -r $dir
else 
mkdir -p $dir
fi
done 

awk -F"\n" -vRS="---\n" '
    {
       for(i=0;i<NF;i++){
           if($i~/^kind:/){
               split($i,a,":");
               gsub(" ","",a[2]);
               if (a[2]=="Role"){
                   print $0 > "'"$workdir"'/tmp/rbac/role.yaml"
               }else if(a[2]=="RoleBinding"){
                   print $0 > "'"$workdir"'/tmp/rbac/rolebing.yaml"
               }else if(a[2]=="ClusterRole"){
                   print $0 > "'"$workdir"'/tmp/rbac/clusterrole.yaml"
               }else if(a[2]=="ClusterRoleBinding"){
                   print $0 > "'"$workdir"'/tmp/rbac/clusterrolebing.yaml"
               }else if(a[2]=="Service"){
                   print "---\n" >> "'"$workdir"'/tmp/service/service.yaml";
                   print $0 >> "'"$workdir"'/tmp/service/service.yaml";
               }else if(a[2]=="DaemonSet"){
                   print $0 > "'"$workdir"'/tmp/daemonset/limb-daemonset.yaml"
               }else if(a[2]=="Deployment"){
                   print $0 > "'"$workdir"'/tmp/deployment/brain-deployment.yaml"
               }else if(a[2]=="CustomResourceDefinition"){
                   print $0 > "'"$workdir"'/tmp/crds/devicelink.yaml"
               }
            }
       }
    }
' $workdir/octopus_all_in_one.yaml



for file in $workdir/tmp/rbac/*
do
echo ${file}
echo $workdir/tmp/tmprbac/${file##*/}
sed -e "/labels:/{n;N;N;s/.*/    {{- include octopus.labels . | nindent 4 }}/}" -e "/namespace:/{s/.*/  namespace: {{ .Release.Namespace }}/}" ${file} > $workdir/tmp/tmprbac/${file##*/}

if [ ${file##*/} == "role.yaml" ];then
sed -i "/name:/{s/.*/  name: {{ .Release.Name }}-leader-election-rol/}" $workdir/tmp/tmprbac/${file##*/}
elif [ ${file##*/} == "rolebing.yaml" ];then
sed -i "/name: octopus-leader-election-rolebinding/{s/.*/  name: {{ .Release.Name }}-leader-election-rolebinding/}"  $workdir/tmp/tmprbac/${file##*/}
sed -i "/roleRef:/{n;n;n;s/.*/  name: {{ .Release.Name }}-election-role/}" $workdir/tmp/tmprbac/${file##*/}
elif [ ${file##*/} == "clusterrole.yaml" ];then
sed -i "/name:/{s/.*/  name: {{ .Release.Name }}-manager-role/}" $workdir/tmp/tmprbac/${file##*/}
else [ ${file##*/} == "clusterrolebing.yaml" ]
sed -i "/name: octopus-manager-rolebinding/{s/.*/  name: {{ .Release.Name }}-manager-rolebinding/}" $workdir/tmp/tmprbac/${file##*/}
sed -i "/roleRef:/{n;n;n;s/.*/  name: {{ .Release.Name }}-manager-role/}" $workdir/tmp/tmprbac/${file##*/}
fi

cat $workdir/tmp/tmprbac/${file##*/} >> $workdir/tmp/tmprbac/rbac.yaml
sed -i '$a\---' $workdir/tmp/tmprbac/rbac.yaml
done

cp $workdir/tmp/tmprbac/rbac.yaml $workdir/tmp/template/rbac.yaml


for file in $workdir/tmp/service/*
do
sed -e "/labels:/{n;N;N;s/.*/    {{- include octopus.labels . | nindent 4 }}/}" -e "/namespace:/{s/.*/  namespace: {{ .Release.Namespace }}/}" ${file} > $workdir/tmp/template/${file##*/}
sed -i "/name: octopus-brain/{s/.*/  name: {{ template "octopus.fullname.brain" . }}/}" $workdir/tmp/template/${file##*/}
sed -i "/name: octopus-limb/{s/.*/  name: {{ template "octopus.fullname.limb" . }}/}" $workdir/tmp/template/${file##*/}
sed -i "/selector/{n;N;N;s/.*/    {{- include "octopus.selectorLabels" . | nindent 4 }}/}" $workdir/tmp/template/${file##*/}
done 


for file in $workdir/tmp/daemonset/*
do
echo ${file}
echo $workdir/tmp/template/${file##*/}
sed -e "/^\s\{2\}labels:/{n;N;N;s/.*/    {{- include octopus.labels . | nindent 4 }}/}" ${file} > $workdir/tmp/template/${file##*/}
sed -i "/namespace: octopus-system/{s/.*/  namespace: {{ .Release.Namespace }}/}"  $workdir/tmp/template/${file##*/}
sed -i "/name: octopus-limb/{s/.*/  name: {{ template "octopus.fullname.limb" . }}/}" $workdir/tmp/template/${file##*/}
sed -i "/matchLabels:/{n;N;N;s/.*/      {{- include "octopus.selectorLabels" . | nindent 6 }}/}" $workdir/tmp/template/${file##*/}
sed -i "/^\s\{6\}labels:/{n;N;N;s/.*/        {{- include "octopus.selectorLabels" . | nindent 8 }}/}" $workdir/tmp/template/${file##*/}
sed -i "/^\s\{4\}spec:/a\      {{- with .Values.global.imagePullSecrets }}\n\
      imagePullSecrets:\n\
        {{- toYaml . | nindent 8 }}\n\
      {{- end }}" $workdir/tmp/template/${file##*/}
sed -e "/^\s\{6\}affinity:/,+13d" -e "/^\s\{4\}spec:/a\      {{- with .Values.octopus.affinity }}\n\
      affinity:\n\
        {{- toYaml . | nindent 8 }}\n\
      {{- end }}\n\
      {{- with .Values.octopus.tolerations }}" -i $workdir/tmp/template/${file##*/}
sed -e "/^\s\{6\}tolerations:/,+1d"  -e "/^\s\{4\}spec:/a\      {{- with .Values.octopus.tolerations }}\n\
      tolerations:\n\
        {{- toYaml . | nindent 8 }}\n\
      {{- end }}" -i $workdir/tmp/template/${file##*/}
sed -i "/^\s\{4\}spec:/a\      nodeSelector:\n\
      {{- with .Values.octopus.nodeSelector }}\n\
        {{- toYaml . | nindent 8 }}\n\
      {{- end }}" $workdir/tmp/template/${file##*/}
sed -i "/image: cnrancher\/octopus/{s/.*/        image: {{ .Values.octopus.image.repository }}:{{ .Values.octopus.image.tag }}/}" $workdir/tmp/template/${file##*/}
sed -i "/imagePullPolicy:/{s/.*/        imagePullPolicy: {{ .Values.octopus.image.pullPolicy }}/}" $workdir/tmp/template/${file##*/}
sed -i "/image:/a\        resources:\n\
          {{- toYaml .Values.octopus.resources | nindent 12 }}" $workdir/tmp/template/${file##*/}
done


for file in $workdir/tmp/deployment/*
do
echo ${file}
echo $workdir/tmp/template/${file##*/}
sed -e "/^\s\{2\}labels:/{n;N;N;s/.*/    {{- include octopus.labels . | nindent 4 }}/}" ${file} > $workdir/tmp/template/${file##*/}
sed -i "/name: octopus-brain/{s/.*/  name: {{ template "octopus.fullname.brain" . }}/}" $workdir/tmp/template/${file##*/}
sed -i "/namespace: octopus-system/{s/.*/  namespace: {{ .Release.Namespace }}/}" $workdir/tmp/template/${file##*/}
sed -i "/^\s\{2\}replicas:/{s/.*/  replicas: {{ .Values.octopus.replicaCount }}/}" $workdir/tmp/template/${file##*/}
sed -i "/matchLabels:/{n;N;N;s/.*/      {{- include "octopus.selectorLabels" . | nindent 6 }}/}" $workdir/tmp/template/${file##*/}
sed -i "/^\s\{6\}labels:/{n;N;N;s/.*/        {{- include "octopus.selectorLabels" . | nindent 8 }}/}" $workdir/tmp/template/${file##*/}
sed -i "/^\s\{4\}spec:/a\      {{- with .Values.global.imagePullSecrets }}\n\
      imagePullSecrets:\n\
        {{- toYaml . | nindent 8 }}\n\
      {{- end }}" $workdir/tmp/template/${file##*/}
sed -e "/^\s\{6\}affinity:/,+13d" -e "/^\s\{4\}spec:/a\      {{- with .Values.octopus.affinity }}\n\
      affinity:\n\
        {{- toYaml . | nindent 8 }}\n\
      {{- end }}" -i $workdir/tmp/template/${file##*/}
sed -e "/^\s\{6\}tolerations:/,+1d"  -e "/^\s\{4\}spec:/a\      {{- with .Values.octopus.tolerations }}\n\
      tolerations:\n\
        {{- toYaml . | nindent 8 }}\n\
      {{- end }}" -i $workdir/tmp/template/${file##*/}
sed -i "/^\s\{4\}spec:/a\      nodeSelector:\n\
      {{- with .Values.octopus.nodeSelector }}\n\
        {{- toYaml . | nindent 8 }}\n\
      {{- end }}" $workdir/tmp/template/${file##*/}
sed -i "/image: cnrancher\/octopus/{s/.*/        image: {{ .Values.octopus.image.repository }}:{{ .Values.octopus.image.tag }}/}" $workdir/tmp/template/${file##*/}
sed -i "/imagePullPolicy:/{s/.*/        imagePullPolicy: {{ .Values.octopus.image.pullPolicy }}/}" $workdir/tmp/template/${file##*/}
sed -i "/image:/a\        resources:\n\
          {{- toYaml .Values.octopus.resources | nindent 12 }}" $workdir/tmp/template/${file##*/}
done