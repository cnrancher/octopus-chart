{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "octopus.name" -}}
{{- default .Chart.Name .Values.octopus.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "octopus.fullname" -}}
{{- if .Values.octopus.fullnameOverride -}}
{{- .Values.octopus.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.octopus.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "octopus.fullname.brain" -}}
{{- printf "%s-%s" .Release.Name "brain" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "octopus.fullname.limb" -}}
{{- printf "%s-%s" .Release.Name "limb" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "octopus.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "octopus.labels" -}}
helm.sh/chart: {{ include "octopus.chart" . }}
{{ include "octopus.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "octopus.selectorLabels" -}}
app.kubernetes.io/name: {{ include "octopus.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "octopus.serviceAccountName" -}}
{{- printf "%s-%s" .Release.Name .Values.global.serviceAccount.name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
