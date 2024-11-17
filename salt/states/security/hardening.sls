sshd_config:
  file.managed:
    - name: /etc/ssh/sshd_config
    - source: salt://security/files/sshd_config
    - user: root
    - group: root
    - mode: 600

disable_root_login:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: '^PermitRootLogin.*$'
    - repl: 'PermitRootLogin no' 