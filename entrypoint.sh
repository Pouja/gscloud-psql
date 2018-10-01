#!/bin/sh

# Initialize gcloud
gcloud auth activate-service-account --key-file /cred/GOOGLE_SERVICE_ACCOUNT_JSON_KEY
gcloud init --console-only --configuration default
gcloud config set core/project $PROJECT_ID

# We have to export variables otherwise postgres will not pick them up
export PGPASSWORD=${POSTGRES_PASSWORD:-postgres}
export PGUSER=${POSTGRES_USER:-postgres}
export PGDATABASE=${POSTGRES_DB:-postgres}
export PGHOST=${POSTGRES_HOST:-postgres}
export PGPORT=${POSTGRES_PORT:-5432}

if [[ -z $RESTORE ]]; then
    # Filename will be the name of the db plus the timestamp
    DATE=$(date +"%Y%m%d-%H%M%S")

    # Create a dump with drop/create statements
    pg_dump -c $PGDATABASE > $NAME-$DATE.txt

    # Copy the file to the bucket
    gsutil cp $NAME-$DATE.txt gs://$BUCKET/backups/$NAMESPACE/$NAME/
else
    gsutil cp gs://$BUCKET/backups/$NAMESPACE/$NAME/$RESTORE db.txt
    psql $PGDATABASE < db.txt
fi;