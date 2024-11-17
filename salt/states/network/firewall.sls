iptables_install:
  pkg.installed:
    - name: iptables

firewall_rules:
  iptables.append:
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - match: state
    - connstate: ESTABLISHED,RELATED
    - save: True 