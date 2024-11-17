application_config:
  file.managed:
    - name: /etc/application/config.yml
    - source: salt://application/files/config.yml.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644 