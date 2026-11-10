# syntax=docker/dockerfile:1
FROM node:24.22.2-alpine@sha256:a34ab6d7f6f4813f4d0c5469d74685604b962fbdbf5793a7bc7b4998ecb867c8 AS base

FROM base AS serve
WORKDIR /opt/serve
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts --no-audit --no-fund \
 && npm cache clean --force

FROM base AS tree
ARG TREE=fixture
ARG CLIENT_CONFIG_COMMIT
COPY ${TREE}/ /tree/
RUN test -n "$CLIENT_CONFIG_COMMIT" \
 && rm -f /tree/stats.json \
 && chmod -R a+rX /tree

FROM base
ARG CLIENT_CONFIG_COMMIT
LABEL org.freecodecamp.client-config.commit=$CLIENT_CONFIG_COMMIT
ENV NO_UPDATE_CHECK=1
WORKDIR /srv/client
COPY --from=serve /opt/serve/node_modules /opt/serve/node_modules
COPY serve.json ./
COPY --from=tree --chown=0:0 /tree/ ./releases/current/
USER 1000:1000
EXPOSE 8080
CMD ["/opt/serve/node_modules/.bin/serve", \
     "-c", "../../serve.json", "releases/current", "-l", "8080"]
