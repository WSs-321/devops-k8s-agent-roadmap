From node:22-alpine AS builder

WORKDIR /app

COPY package*.json .

RUN npm ci --omit=dev


FROM node:22-alpine AS runner

ARG VERSION=dev
ARG BUILD_DATE=unknown

WORKDIR /app

RUN adduser -D app

COPY --chown=app:app --from=builder /app/node_modules ./node_modules
COPY --chown=app:app src ./src

USER app

EXPOSE 3000

ENV NODE_ENV=production
ENV GREETING="Hello, World!"

LABEL org.opencontainers.image.title="roadmap"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"

CMD ["node", "src/index.js"]
