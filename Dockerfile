FROM eclipse-temurin:21-jre-alpine

WORKDIR /server

# This is a placeholder. The actual server files will be mounted here as a volume.
# This command ensures the directory is created with the correct permissions if it doesn't exist.
RUN mkdir -p /server

# We expect a start script to be provided by the user.
ENTRYPOINT ["sh", "-c", "chmod +x /server/start.sh && /server/start.sh"]