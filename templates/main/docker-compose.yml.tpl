services:
  app:
    image: ${docker_image}:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
    env_file:
      - .env
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    command: redis-server --appendonly yes

  alloy:
    image: grafana/alloy:latest
    restart: unless-stopped
    ports:
      - "4317:4317"
      - "4318:4318"
      - "12345:12345"
    volumes:
      - ./alloy-config.alloy:/etc/alloy/config.alloy
      - /var/run/docker.sock:/var/run/docker.sock:ro
    command: run /etc/alloy/config.alloy

volumes:
  redis-data:
