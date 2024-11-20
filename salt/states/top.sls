base:
  '*':
    - system.init
    - system.packages
    - system.users
  'salt-minion':
    - system.download_file