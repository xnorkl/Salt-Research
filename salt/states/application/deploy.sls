application_directory:
  file.directory:
    - name: /opt/application
    - user: app
    - group: app
    - mode: 755
    - makedirs: True

application_service:
  service.running:
    - name: application
    - enable: True
    - require:
      - file: application_directory 