{{/*
Expand the name of the chart.
*/}}
{{- define "openshift-ai.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "openshift-ai.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "openshift-ai.labels" -}}
helm.sh/chart: {{ include "openshift-ai.chart" . }}
app.kubernetes.io/name: {{ include "openshift-ai.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Returns true when a DSC component managementState is Managed.
*/}}
{{- define "openshift-ai.componentManaged" -}}
{{- $state := .state | default "Removed" -}}
{{- eq $state "Managed" -}}
{{- end }}

{{/*
Shared resource defaults for RHOAI controller patches.
*/}}
{{- define "openshift-ai.controllerResourcesPatchDefaults" -}}
{{- $patch := (.Values.controllerResourcesPatch | default dict) -}}
{{- $defaults := ($patch.defaults | default dict) -}}
{{- $requests := ($defaults.requests | default dict) -}}
{{- $limits := ($defaults.limits | default dict) -}}
requests:
  memory: {{ default "3Gi" $requests.memory }}
  cpu: {{ default "200m" $requests.cpu }}
limits:
  memory: {{ default "5Gi" $limits.memory }}
  cpu: {{ default "500m" $limits.cpu }}
{{- end }}

{{/*
Build the list of enabled controller resource patch targets.
*/}}
{{- define "openshift-ai.controllerResourcePatchTargets" -}}
{{- $patch := (.Values.controllerResourcesPatch | default dict) -}}
{{- if not (default true $patch.enabled) -}}
targets: []
{{- else -}}
{{- $defaults := include "openshift-ai.controllerResourcesPatchDefaults" . | fromYaml -}}
{{- $dsc := (.Values.dataScienceCluster | default dict) -}}
{{- $components := ($dsc.components | default dict) -}}
{{- $kserve := ($components.kserve | default dict) -}}
{{- $maas := ($kserve.modelsAsService | default dict) -}}
{{- $llmisvc := ($components.llamastackoperator | default dict) -}}
{{- $dsci := (.Values.dataScienceClusterInitialization | default dict) -}}
{{- $monitoring := ($dsci.monitoring | default dict) -}}
{{- $applicationsNamespace := (default "redhat-ods-applications" $dsci.applicationsNamespace) -}}
{{- $monitoringNamespace := (default "redhat-ods-monitoring" $monitoring.namespace) -}}
{{- $targets := list -}}
{{- $maasCfg := ($patch.maasController | default dict) -}}
{{- if and (default true $maasCfg.enabled) (include "openshift-ai.componentManaged" (dict "state" ($maas.managementState | default "Removed"))) (eq ($maas.managementState | default "Removed") "Managed") -}}
{{- $targets = append $targets (dict
  "key" "maas-controller"
  "namespace" (default $applicationsNamespace $maasCfg.namespace)
  "workloadKind" "deployment"
  "workloadName" (default "maas-controller" $maasCfg.workloadName)
  "container" (default "manager" $maasCfg.container)
  "openTelemetryCollector" ""
  "requests" (mergeOverwrite (deepCopy $defaults.requests) ($maasCfg.requests | default dict))
  "limits" (mergeOverwrite (deepCopy $defaults.limits) ($maasCfg.limits | default dict))
) -}}
{{- end -}}
{{- $kserveCfg := ($patch.kserveController | default dict) -}}
{{- if and (default true $kserveCfg.enabled) (include "openshift-ai.componentManaged" (dict "state" ($kserve.managementState | default "Removed"))) (eq ($kserve.managementState | default "Removed") "Managed") -}}
{{- $targets = append $targets (dict
  "key" "kserve-controller"
  "namespace" (default $applicationsNamespace $kserveCfg.namespace)
  "workloadKind" "deployment"
  "workloadName" (default "kserve-controller-manager" $kserveCfg.workloadName)
  "container" (default "manager" $kserveCfg.container)
  "openTelemetryCollector" ""
  "requests" (mergeOverwrite (deepCopy $defaults.requests) ($kserveCfg.requests | default dict))
  "limits" (mergeOverwrite (deepCopy $defaults.limits) ($kserveCfg.limits | default dict))
) -}}
{{- end -}}
{{- $llmisvcCfg := ($patch.llmisvcController | default dict) -}}
{{- if and (default true $llmisvcCfg.enabled) (include "openshift-ai.componentManaged" (dict "state" ($llmisvc.managementState | default "Removed"))) (eq ($llmisvc.managementState | default "Removed") "Managed") -}}
{{- $targets = append $targets (dict
  "key" "llmisvc-controller"
  "namespace" (default $applicationsNamespace $llmisvcCfg.namespace)
  "workloadKind" "deployment"
  "workloadName" (default "llmisvc-controller-manager" $llmisvcCfg.workloadName)
  "container" (default "manager" $llmisvcCfg.container)
  "openTelemetryCollector" ""
  "requests" (mergeOverwrite (deepCopy $defaults.requests) ($llmisvcCfg.requests | default dict))
  "limits" (mergeOverwrite (deepCopy $defaults.limits) ($llmisvcCfg.limits | default dict))
) -}}
{{- end -}}
{{- $collectorCfg := ($patch.dataScienceCollector | default dict) -}}
{{- if and (default true $collectorCfg.enabled) (include "openshift-ai.componentManaged" (dict "state" ($monitoring.managementState | default "Removed"))) (eq ($monitoring.managementState | default "Removed") "Managed") -}}
{{- $targets = append $targets (dict
  "key" "data-science-collector"
  "namespace" (default $monitoringNamespace $collectorCfg.namespace)
  "workloadKind" "statefulset"
  "workloadName" (default "data-science-collector-collector" $collectorCfg.workloadName)
  "container" (default "otc-container" $collectorCfg.container)
  "openTelemetryCollector" (default "data-science-collector" $collectorCfg.openTelemetryCollector)
  "requests" (mergeOverwrite (deepCopy $defaults.requests) ($collectorCfg.requests | default dict))
  "limits" (mergeOverwrite (deepCopy $defaults.limits) ($collectorCfg.limits | default dict))
) -}}
{{- end -}}
targets:
{{- toYaml $targets | nindent 0 }}
{{- end -}}
{{- end -}}
