include:
  - system.packages
  - system.users

timezone:
  timezone.system:
    - name: UTC

set_hostname:
  host.present:
    - ip: 127.0.0.1
    - names:
      - {{ grains['id'] }}
      - localhost

write_hostname:
  file.managed:
    - name: /etc/hostname
    - contents: {{ grains['id'] }}
  cmd.run:
    - name: hostname {{ grains['id'] }}
    - unless: test "$(hostname)" = "{{ grains['id'] }}"