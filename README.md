# Update/Restore backup
An docker image utility to use in your kubernetes cluster to update and restore backups from your postgres database.
The image is build upon alpine to be as small as possible.

You could use this as a basis to perform other gcloud util commands.

## Setup
You will need to create a service account in your Google Console (IAM & Admin > IAM) with read and write access to your bucket.  
Export the credentials of that service account in JSON format and create a secret:
```bash
kubectl create secret generic gcs-secret \
    --from-file=./GOOGLE_SERVICE_ACCOUNT_JSON_KEY
```

That will be mounted to `/cred`.

## Environment variables
| Name | Description |
|-------------------|-----------------------------------------------------------------------------------------------------------------------------|
| POSTGRES_PASSWORD | default: postgres |
| POSTGRES_USER | default: postgres |
| POSTGRES_DB | default: postgres |
| POSTGRES_HOST | default: postgres |
| POSTGRES_PORT | default: 5432 |
| NAME | The name of the backup file will be constructed with $NAME-$DATE.txt where date is in YYYYMMDD-HHMMSS format. |
| BUCKET | The google storage bucket name where you want to store it. |
| NAMESPACE | You can specify the namespace in which the database runs. This only influences the path in which the backup will be placed. |
| PROJECT_ID | The google project id. |
| RESTORE | If specified it will use this filename to restore your database. |

The backups will be placed in `$BUCKET/backups/$NAMESPACE/$NAME/`

## Locally
You can also try this image locally.
You should have a directory containing the GOOGLE_SERVICE_ACCOUNT_JSON_KEY file (the service account credentials).

```bash
docker run \
    --rm \
    -e PROJECT_ID= \
    -e BUCKET= \
    -e NAMESPACE= \
    -e NAME= \
    -e RESTORE= \
    -v $PWD/cred:/cred \
    --name gcloud \
    gcloud-psql:1
```

## Backup
Following file is an example of a cronjob in your kubernetes cluster to perform scheduled backups
```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: scheduled-backup-db
spec:
  schedule: "*/2 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          volumes:
          - name: gcs-secret
            secret:
              secretName: gcs-secret
          containers:
          - name: restore-db
            image: gcloud-psql:1
            volumeMounts:
            - name: gcs-secret
              mountPath: "/cred"
              readOnly: true
            env:
              - name: POSTGRES_HOST
                value: database
              - name: POSTGRES_PASSWORD
                valueFrom:
                  secretKeyRef:
                    name: database
                    key: postgres-password
              - name: NAMESPACE
                valueFrom:
                  fieldRef:
                    fieldPath: metadata.namespace
              - name: NAME
                value: NAME_OF_YOUR_BACKUP_FILE
              - name: PROJECT_ID
                value: YOUR_RPOJECT_ID
              - name: BUCKET
                value: YOUR_BUCKET_NAME
```

## Restore from specific file
```yaml
# Restore a specific backup from our bucket
apiVersion: batch/v1
kind: Job
metadata:
  name: restore-db
spec:
  backoffLimit: 1
  template:
    spec:
      restartPolicy: Never
      volumes:
      - name: gcs-secret
        secret:
          secretName: gcs-secret
      containers:
      - name: restore-db
        image: gcloud-psql:1
        volumeMounts:
        - name: gcs-secret
          mountPath: "/cred"
          readOnly: true
        env:
          - name: POSTGRES_HOST
            value: database
          - name: POSTGRES_PASSWORD
            valueFrom:
              secretKeyRef:
                name: database
                key: postgres-password
          - name: NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: NAME
            value: simple-db
          - name: RESTORE
            value: YOUR_BACKUP_FILE_NAME.txt
          - name: PROJECT_ID
            value: YOUR_PROJECT_ID
          - name: BUCKET
            value: YOUR_BUCKET_NAME
```