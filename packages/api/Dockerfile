FROM public.ecr.aws/docker/library/node:20-alpine

WORKDIR /app

# Install OpenSSL and required dependencies for Prisma
RUN apk add --no-cache openssl openssl-dev libc6-compat

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies
RUN npm install

# Generate Prisma Client
RUN npx prisma generate

# Copy source code
COPY . .

# Build TypeScript
RUN npm run build

# Expose port
EXPOSE 5000

# Create entrypoint script to run migrations before starting
RUN echo '#!/bin/sh' > /app/entrypoint.sh && \
    echo 'echo "Running Prisma migrations..."' >> /app/entrypoint.sh && \
    echo 'npx prisma migrate deploy' >> /app/entrypoint.sh && \
    echo 'echo "Starting server..."' >> /app/entrypoint.sh && \
    echo 'exec npm start' >> /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh

# Start server with migrations
CMD ["/app/entrypoint.sh"]

