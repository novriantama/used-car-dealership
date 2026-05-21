# Stage 1: Build the Flutter Web application
FROM debian:bookworm-slim AS build-env

# Install Flutter dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter stable SDK with depth 1 to speed up the download
RUN git clone --depth 1 https://github.com/flutter/flutter.git -b stable /usr/local/flutter

# Add flutter to system PATH
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Pre-download development binaries and verify environment
RUN flutter doctor -v

# Set the working directory
WORKDIR /app

# Copy files and download dependencies
COPY pubspec.yaml ./
RUN flutter pub get

# Copy all source files
COPY . .

# Compile Flutter application to Web assets
RUN flutter build web --release

# Stage 2: Serve the compiled static assets using Nginx
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
