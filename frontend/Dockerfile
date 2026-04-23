# Stage 1
#FROM ghcr.io/cirruslabs/flutter:3.22.0 AS builder
FROM ghcr.io/cirruslabs/flutter:3.41.1

WORKDIR /app
COPY . .

RUN flutter pub get

ARG API_BASE_URL=https://shieldscan-backend-oci6nmhk5q-as.a.run.app

RUN flutter build web --release \
  --dart-define=API_BASE_URL=${API_BASE_URL}

# Stage 2
FROM nginx:alpine

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]