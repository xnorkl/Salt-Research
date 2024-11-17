include:
  - network.firewall
  - network.routing

network_tools:
  pkg.installed:
    - pkgs:
      - net-tools
      - tcpdump
      - nmap 