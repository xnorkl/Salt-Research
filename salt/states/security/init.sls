include:
  - security.hardening
  - security.compliance

security_packages:
  pkg.installed:
    - pkgs:
      - fail2ban
      - rkhunter
      - auditd 