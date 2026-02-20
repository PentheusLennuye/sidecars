<source>
  @type syslog
  port 514
  bind 127.0.0.1
  tag sidecars
  <parse>
    @type syslog
    message_format rfc5424
    time_format %Y-%m-%dT%H:%M:%S.%L%z
  </parse>
  severity_key severity
  facility_key facility
</source>
<match sidecars.**>
  @type syslog_tls
  host {{ required "logging.host is required" .Values.global.logging.host | quote }}
  port  {{ required "logging.port is required" .Values.global.logging.port }}
  idle_timeout {{ required "logging.idleTimeout is required" .Values.global.logging.idleTimeout | quote }}
  facility_key facility
  hostname_key host
  app_name_key ident
  proc_id_key pid
  msgid_key msgid
  message_key message
  severity_key severity
</match>
<match **>
  @type stdout
  use_logger false
  <format>
    @type json
  </format>
  <inject>
    time_key time
    time_type string
    time_format %Y-%m-%dT%H:%M:%S.%NZ
  </inject>
</match>
