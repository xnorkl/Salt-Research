cis_benchmarks:
  pkg.installed:
    - pkgs:
      - aide
      - audit
      - libpam-pwquality

selinux_config:
  file.managed:
    - name: /etc/selinux/config
    - contents: |
        SELINUX=enforcing
        SELINUXTYPE=targeted 