#!/usr/bin/env bash

source ./prod/.env
PROD_PG_USER="$POSTGRES_USER"
PROD_PG_DB="$POSTGRES_DB"

source ./staging/.env
STAGING_PG_USER="$POSTGRES_USER"
STAGING_PG_DB="$POSTGRES_DB"

# drop the tableee
echo "Dropping staging database $STAGING_PG_DB..."
docker exec -t aragok-staging-postgres dropdb -U "$STAGING_PG_USER" -f "$STAGING_PG_DB"
echo "Creating staging database $STAGING_PG_DB..."
docker exec -t aragok-staging-postgres createdb -U "$STAGING_PG_USER" "$STAGING_PG_DB"

echo "Dumping brod database $PROD_PG_DB..."
docker exec -t aragok-prod-postgres pg_dump -U "$PROD_PG_USER" -d "$PROD_PG_DB" > dump.sql

echo "Importing dump..."
docker cp dump.sql aragok-staging-postgres:/tmp/dump.sql
docker exec -t aragok-staging-postgres psql -U "$STAGING_PG_USER" -d "$STAGING_PG_DB" -f /tmp/dump.sql

rm dump.sql
echo "Complete!"
