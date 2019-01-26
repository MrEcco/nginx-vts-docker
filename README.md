
# Nginx VTS+TLSv1.3+PageSpeed

This is docker image with custom builded nginx with special features:
1. **openssl-1.1.1a** - include TLSv1.3 support
2. **nginx-1.15.8** - latest version (29.09.2018)
3. **nginx-module-vts** - required for work nginx-vts exporter for prometheus
4. **pagespeed-1.13.35.2** - latest version (29.09.2018)
5. All other features, which ubuntu-bionic repository nginx have

Each version is latest for image build time.

## Docker image

```bash
docker pull mrecco/nginx
```

See me on dockerhub: https://hub.docker.com/r/mrecco/nginx

## Customizing

In **Dockerfile** you can specify version for OpenSSL, nginx and PageSpeed. 

For comfortable use, you can specify *latest* for **nginx** and *latest-stable* for **PageSpeed**.

## Configuration

Use this references:

1. http://nginx.org/en/docs/
2. https://www.modpagespeed.com/doc/configuration
3. https://github.com/vozlt/nginx-module-vts

## In addiion

1. Grafana dashboard for Nginx-VTS metrics via Prometheus
https://grafana.com/dashboards/2949
