mysql_install:
  pkg.installed:
    - name: mysql-server

mysql_service:
  service.running:
    - name: mysql
    - enable: True
    - require:
      - pkg: mysql_install 