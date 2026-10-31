{{- /* chezmoi:modify-template */ -}}
{{- /* Other dotfiles (e.g. work) append marked blocks to the live file:
       <!-- BEGIN external:NAME --> ... <!-- END external:NAME -->
       Keep them so chezmoi doesn't revert them. Each block renders as a blank
       line, the block, then a newline, which is how they are appended. */ -}}
{{- $live := "" -}}
{{- if .chezmoi.stdin }}{{ $live = .chezmoi.stdin }}{{ end -}}
{{ include "private_dot_config/agents/AGENTS.md" -}}
{{- range $block := regexFindAll "(?s)<!-- BEGIN external:[^>]*-->.*?<!-- END external:[^>]*-->" $live -1 }}
{{ $block }}
{{ end -}}
