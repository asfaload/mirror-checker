FROM alpine

RUN apk add git bash althttpd

COPY script.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# user get id 100, group id 101
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
ENTRYPOINT ["/entrypoint.sh"]
