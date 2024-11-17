include:
  - application.deploy
  - application.config

# Common application dependencies
application_packages:
  pkg.installed:
    - pkgs:
      - nginx
      - nodejs
      - npm 