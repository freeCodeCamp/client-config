# syntax=docker/dockerfile:1
FROM node:26.13.1-alpine@sha256:6bd9ab43c0ec0190ca7b2d193906cb8b7edf6e7f4afa43ddeccd6452710bffb5 AS base

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
RUN rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx
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
