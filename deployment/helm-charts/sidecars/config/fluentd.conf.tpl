<source>
  @type syslog
  port 5140
  bind 127.0.0.1
  tag mqworker
  <transport tcp>
  </transport>
  <parse>
    @type syslog
    message_format rfc3164
  </parse>
</source>
<match **>
  @type stdout
</match>
