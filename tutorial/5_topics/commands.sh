dune exec tutorial/5_topics/receive_logs_topic.exe -- "#"
dune exec tutorial/5_topics/receive_logs_topic.exe -- "kern.*"
dune exec tutorial/5_topics/receive_logs_topic.exe -- "*.critical"
dune exec tutorial/5_topics/receive_logs_topic.exe -- "kern.*" "*.critical"
dune exec tutorial/5_topics/emit_log_topic.exe -- "kern.critical" "A critical kernel error"