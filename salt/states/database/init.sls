include:
  - database.mysql
  - database.postgresql

database_common_packages:
  pkg.installed:
    - pkgs:
      - database-client
      - database-common 