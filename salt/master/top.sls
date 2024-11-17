base:
  '*':
    - system
    - security.hardening
  'role:application':
    - match: grain
    - application
  'role:database':
    - match: grain
    - database
  'role:network':
    - match: grain
    - network 