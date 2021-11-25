# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import alcali with context %}

{% if alcali.config.db_backend == 'mysql' %}
  {% set db_connector = 'mysqlclient' %}
  {% set db_requirements = {
      'RedHat': ['mariadb-devel', 'python3-devel'],
      'Arch': ['mariadb-libs'],
      'Debian': ['default-libmysqlclient-dev', 'python3-dev'],
      'FreeBSD': ['curl'],
  }.get(grains.os_family) %}
{% endif %}

{% if alcali.config.db_backend == 'postgresql' %}
  {% set db_connector = 'psycopg2' %}
  {% set db_requirements = {
      'RedHat': ['libpq-devel', 'python3-devel'],
      'Arch': ['postgresql-libs'],
      'Debian': ['libpq-dev', 'python3-dev'],
      'FreeBSD': ['postgresql-libpqxx'],
  }.get(grains.os_family) %}
{% endif %}

{% set venv_requirements = {
    'RedHat': ['python-virtualenv'],
    'Arch': ['python-virtualenv'],
    'Debian': ['virtualenv', 'python3-pip', 'python3-virtualenv', 'python3-venv'],
    'FreeBSD': ['py38-pip', 'py38-virtualenv'],
}.get(grains.os_family) %}

{%- if alcali.config.auth_backend == 'ldap' %}
  {%- set venv_requirements = venv_requirements + alcali.ldap_pks %}
{%- endif %}

alcali-package-install-pkg-installed:
  pkg.installed:
    - pkgs:
      - git
      - gcc

{% for pkg in db_requirements %}
{{ pkg }}:
  pkg.installed:
    - name: {{ pkg }}
{% endfor %}

{% for venv_pkg in venv_requirements %}
{{ venv_pkg }}:
  pkg.installed:
    - name: {{ venv_pkg }}
{% endfor %}

alcali-package-install-git-latest:
  git.latest:
    - name: {{ alcali.deploy.repository }}
    - target: {{ alcali.deploy.directory }}/code
    - user: {{ alcali.deploy.user }}
    - rev: {{ alcali.deploy.rev }}

alcali-package-install-virtualenv-managed:
  virtualenv.managed:
    - name: {{ alcali.deploy.directory }}/.venv
    - user: {{ alcali.deploy.user }}
    - python: {{ alcali.deploy.runtime }}
    - system_site_packages: False
    - requirements: {{ alcali.deploy.directory }}/code/requirements/prod.txt
    - require:
      - git: alcali-package-install-git-latest

alcali-package-install-db-pip-installed:
  pip.installed:
    - name: {{ db_connector }}
    - user: {{ alcali.deploy.user }}
    - cwd: {{ alcali.deploy.directory }}
    - bin_env: {{ alcali.deploy.directory }}/.venv
    - require:
      - virtualenv: alcali-package-install-virtualenv-managed

{% if alcali.config.auth_backend == 'ldap' %}
alcali-package-install-ldap-pip-installed:
  pip.installed:
    - name: alcali-package-install-ldap-pip-installed
    - user: {{ alcali.deploy.user }}
    - cwd: {{ alcali.deploy.directory }}
    - bin_env: {{ alcali.deploy.directory }}/.venv
    - requirements: {{ alcali.deploy.directory }}/code/requirements/ldap.txt
  {%- if grains.os_family == 'FreeBSD' %}
    - env_vars:
        C_INCLUDE_PATH: /usr/local/include
  {%- endif %}
    - require:
      - virtualenv: alcali-package-install-virtualenv-managed
{% endif %}
