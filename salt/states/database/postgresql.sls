postgresql_install:
  pkg.installed:
    - name: postgresql

postgresql_service:
  service.running:
    - name: postgresql
    - enable: True
    - require:
      - pkg: postgresql_install 