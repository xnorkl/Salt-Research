{{ salt['pillar.get']('azure_file_download:destination_path') }}/{{ salt['pillar.get']('azure_file_download:filename') }}:
  file.managed:
    - source: {{ salt['pillar.get']('azure_file_download:source_path') }}{{ salt['pillar.get']('azure_file_download:filename') }}
    - user: admin
    - makedirs: True