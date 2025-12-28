FROM node:20-alpine as build
WORKDIR /app
# Will be completed in T012
COPY . .
RUN echo "Frontend placeholder"

FROM nginx:alpine
COPY --from=build /app /usr/share/nginx/html
