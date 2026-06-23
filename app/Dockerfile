From node:22-alpine AS builder
WORKDIR /app
COPY package*.json .
RUN npm ci --omit=dev


From node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/node_modules ./node_modules
COPY src ./src
EXPOSE 3000
CMD ["node", "SRC/index.js"]
