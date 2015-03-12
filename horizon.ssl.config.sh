#!/bin/bash

a2enmod rewrite
a2enconf openstack-dashboard
a2ensite default-ssl
a2enmod ssl

vim /etc/apache2/sites-enabled/000-default.conf
vim /etc/openstack-dashboard/local_settings.py


service apache2 restart


