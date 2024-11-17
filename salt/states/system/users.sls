admin_group:
  group.present:
    - name: admin
    - system: False

admin_user:
  user.present:
    - name: admin
    - fullname: System Administrator
    - shell: /bin/bash
    - home: /home/admin
    - groups:
      - admin
      - sudo 