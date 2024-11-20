{{ salt['pillar.get']('azure_file_download:destination_path', '/tmp/downloads') }}/{{ salt['pillar.get']('azure_file_download:filename', 'default.txt') }}:
  file.managed:
    - source: {{ salt['pillar.get']('azure_file_download:source_path', 'azurefs://') }}{{ salt['pillar.get']('azure_file_download:filename', 'default.txt') }}
    - user: admin
    - makedirs: True