# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_config_file = tplroot ~ '.config.file' %}
{%- from tplroot ~ "/map.jinja" import alcali with context %}

include:
  - {{ sls_config_file }}


{% if grains['os_family'] == 'FreeBSD' %}

alcali-file-managed-service-running:
  file.managed:
    - name: /usr/local/etc/rc.d/alcali
    - context:
        service: {{ alcali.service.name }}
        directory: {{ alcali.deploy.directory }}
        user: {{ alcali.deploy.user }}
        group: {{ alcali.deploy.group }}
        name: {{ alcali.gunicorn.name }}
        host: {{ alcali.gunicorn.host }}
        port: {{ alcali.gunicorn.port }}
        workers: {{ alcali.gunicorn.workers }}
        timeout: {{ alcali.gunicorn.timeout }}
    - source: salt://alcali/files/alcali.rc.jinja
    - template: jinja
    - mode: '0555'

alcali-service-running-service-running:
  service.running:
    - name: {{ alcali.service.name }}
    - enable: True
    - restart: True
    - order: last
    - init_delay: {{ alcali.service.init_delay }}
    - watch:
      - sls: {{ sls_config_file }}
      - file: alcali-file-managed-service-running

{% else %}

alcali-file-managed-service-running:
  file.managed:
    - name: /etc/systemd/system/{{ alcali.service.name }}.service
    - context:
        service: {{ alcali.service.name }}
        directory: {{ alcali.deploy.directory }}
        user: {{ alcali.deploy.user }}
        group: {{ alcali.deploy.group }}
        name: {{ alcali.gunicorn.name }}
        host: {{ alcali.gunicorn.host }}
        port: {{ alcali.gunicorn.port }}
        workers: {{ alcali.gunicorn.workers }}
        timeout: {{ alcali.gunicorn.timeout }}
    - source: salt://alcali/files/alcali.service.jinja
    - template: jinja
  module.run:
{% if salt["config.get"]("use_superseded") %}  
    - service.systemctl_reload:
{% elif salt['salt_version.greater_than']("3005") %}
    - service.systemctl_reload:
{% else %}
    - name: service.systemctl_reload
{% endif %}
    - onchanges:
      - file: alcali-file-managed-service-running

alcali-service-running-service-running:
  service.running:
    - name: {{ alcali.service.name }}
    - enable: True
    - restart: True
    - order: last
    - watch:
      - sls: {{ sls_config_file }}
      - file: alcali-file-managed-service-running
      - module: alcali-file-managed-service-running
{% endif %}
