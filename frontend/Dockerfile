# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:3.22.0 AS builder

WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .

ARG API_BASE_URL=http://localhost:8080
RUN flutter build web --release \
  --dart-define=API_BASE_URL=${API_BASE_URL} \
  --web-renderer canvaskit

# Stage 2: Serve with nginx
FROM nginx:alpine

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
