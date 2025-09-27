FROM eclipse-temurin:21-jre-alpine

WORKDIR /server
RUN mkdir -p /server

ARG UID=1000
ARG GID=1000

RUN addgroup -S -g $GID javauser && \
    adduser -S -G javauser -u $UID javauser

RUN chown -R javauser:javauser /server
USER javauser

# We expect a start script to be provided by the user.
ENTRYPOINT ["sh", "-c", "chmod +x /server/entrypoint.sh && /server/entrypoint.sh"]
