#!/bin/bash
set -euxo pipefail

# Make sure the deployment group specific variables are available to this
# script.
source ${BASH_SOURCE%/*}/../configs/$DEPLOYMENT_GROUP_NAME-config.conf

# Set some useful variables
DEPLOYMENT_NAME="$APP_NAME"
PROJECT_DIR="/home/datamade/$DEPLOYMENT_NAME"
VENV_DIR="/home/datamade/.virtualenvs/$DEPLOYMENT_NAME"

# Move the contents of the folder that CodeDeploy used to "Install" the app to
# the deployment specific folder
rm -Rf $PROJECT_DIR
mv /home/datamade/la-metro-dashboard-deployment-root $PROJECT_DIR

# Create a deployment specific virtual environment
python3 -m venv $VENV_DIR

# Set the ownership of the project files and the virtual environment
chown -R datamade.www-data $PROJECT_DIR
chown -R datamade.www-data $VENV_DIR

# Make the log directory and set its ownership
mkdir -p /var/log/la-metro-dashboard
chown -R datamade.www-data /var/log/la-metro-dashboard

# Upgrade pip and setuptools. This is needed because sometimes python packages
# that we rely upon will use more recent packaging methods than the ones
# understood by the versions of pip and setuptools that ship with the operating
# system packages.
sudo -H -u datamade $VENV_DIR/bin/pip install --upgrade pip
sudo -H -u datamade $VENV_DIR/bin/pip install --upgrade setuptools

# Install the project requirements into the deployment specific virtual
# environment.
sudo -H -u datamade $VENV_DIR/bin/pip install -r $PROJECT_DIR/requirements.txt --upgrade

# Move project configuration files into the appropriate locations within the project.
mv $PROJECT_DIR/configs/airflow.$DEPLOYMENT_GROUP_NAME.cfg $PROJECT_DIR/airflow.cfg

# OPTIONAL If you're using PostgreSQL, check to see if the database that you
# need is present and, if not, create it setting the datamade user as it's
# owner.
psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '${DATABASE}'" | grep -q 1 || createdb -U postgres -O datamade ${DATABASE}

# Run migrations and other management commands that should be run with
# every deployment
AIRFLOW_HOME=$PROJECT_DIR $VENV_DIR/bin/airflow initdb

# Echo a simple nginx configuration into the correct place, and tell
# certbot to request a cert if one does not already exist.
# Wondering about the DOMAIN variable? It becomes available by source-ing
# the config file (see above).
if [ ! -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem ]; then
    echo "server {
        listen 80;
        server_name $DOMAIN;

        location ~ .well-known/acme-challenge {
            root /usr/share/nginx/html;
            default_type text/plain;
        }

    }" > /etc/nginx/conf.d/$APP_NAME.conf
    service nginx reload
    certbot -n --nginx -d $DOMAIN -m devops@datamade.us --agree-tos
fi

# Move configs files to correct location.
mv -f $PROJECT_DIR/configs/$APP_NAME.$DEPLOYMENT_GROUP_NAME.conf.nginx /etc/nginx/conf.d/$APP_NAME.conf
mv -f $PROJECT_DIR/configs/$APP_NAME.$DEPLOYMENT_GROUP_NAME.conf.supervisor /etc/supervisor/conf.d/$APP_NAME.conf
