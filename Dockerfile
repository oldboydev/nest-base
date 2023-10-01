FROM node:20.6-bookworm-slim AS base
RUN apt-get update && apt-get install -y --no-install-recommends tini
WORKDIR /usr/src/app
COPY tsconfig*.json ./
COPY nest-cli.json ./
COPY test/jest-e2e.json ./
COPY package*.json ./
RUN npm ci --ignore-scripts
COPY src ./src
COPY test ./test
COPY .env ./

FROM base AS build
RUN npm run build
RUN npm prune --production

FROM node:20.6-bookworm-slim AS production 
ENV NODE_ENV=production
EXPOSE 3000
COPY --from=base /usr/bin/tini /usr/bin/tini
USER node
WORKDIR /usr/src/app
COPY --chown=node:node --from=build --chmod=500 /usr/src/app/node_modules ./node_modules
COPY --chown=node:node --from=build --chmod=500 /usr/src/app/dist .
COPY --chown=node:node --from=build --chmod=500 /usr/src/app/.env .
ENTRYPOINT ["/tini", "--"]
CMD ["node", "index"]