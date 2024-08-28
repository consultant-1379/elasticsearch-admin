{{/*
 Create a map from global values with defaults if not in the values file.
*/}}
{{ define "elasticsearch-admin.globalMap" }}
{{- $globalDefaults := dict "timezone" "UTC" -}}
{{- $globalDefaults := merge $globalDefaults (dict "securityPolicy" (dict "rolekind" "")) -}}
{{ if .Values.global }}
{{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
{{ else }}
{{- $globalDefaults | toJson -}}
{{ end }}
{{ end }}

{{/*
Create the name of the service account to use.
*/}}
{{- define "elasticsearch-admin.serviceAccountName" -}}
{{ include "elasticsearch-admin.name" . }}-sa
{{- end }}


{{- /*
common.metadata creates a standard metadata header
Note:
Metadata for configmap is resides inside _configmap.yaml
If any change in the below metadata. Its Mandatory to change in the _configmap.yaml and __metadat_stateful.yaml
*/ -}}
{{ define "elasticsearch-admin.metadata" -}}
name: {{ .Values.service.name  }}
labels:
{{- if .Values.service.name }}
  sgname: {{ .Values.service.name | quote }}
{{- end }}
  heritage: {{ .Release.Service | quote }}
{{- include "elasticsearch-admin.metadata_app_labels" . | indent 2 }}
{{- end -}}

{{/*
Generate labels
*/}}
{{- define "elasticsearch-admin.metadata_app_labels" }}
app: {{ .Values.service.name | quote }}
app.kubernetes.io/name: {{ .Values.service.name | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/version: {{ template "elasticsearch-admin.chart" . }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}

{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "elasticsearch-admin.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "elasticsearch-admin.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "elasticsearch-admin.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "elasticsearch-admin.labels" -}}
helm.sh/chart: {{ include "elasticsearch-admin.chart" . }}
{{ include "elasticsearch-admin.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "elasticsearch-admin.selectorLabels" -}}
app: {{ include "elasticsearch-admin.fullname" . | quote }}
app.kubernetes.io/name: {{ include "elasticsearch-admin.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create image pull secrets
*/}}
{{- define "elasticsearch-admin.pullSecrets" -}}
{{- if .Values.global.pullSecret -}}
{{- print .Values.global.pullSecret -}}
{{- else if .Values.imageCredentials.pullSecret -}}
{{- print .Values.imageCredentials.pullSecret -}}
{{- end -}}
{{- end -}}
