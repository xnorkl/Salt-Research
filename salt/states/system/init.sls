include:
  - system.packages
  - system.users

timezone:
  timezone.system:
    - name: UTC

hostname_config:
  network.system:
    - enabled: True
    - hostname: {{ grains['id'] }} 