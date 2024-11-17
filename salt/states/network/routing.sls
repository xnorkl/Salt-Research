net.ipv4.ip_forward:
  sysctl.present:
    - value: 1

routing_packages:
  pkg.installed:
    - pkgs:
      - quagga
      - bird 