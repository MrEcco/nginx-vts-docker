FROM ubuntu:bionic

LABEL maintainer="Andrey <MrEcco> Burindin"
      address="dron100.1.089@gmail.com"

# Versioning
ARG NGINX_VERSION="latest"
ARG PAGESPEED_VERSION="latest-stable"
ARG OPENSSL_VERSION="1.1.1a"

# Build environment parameters
ARG BUILDROOT="/root"
ARG BUILD_THREADCOUNT="4"

# Source code links
ARG OPENSSL_SOURCE="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
ARG NGINXVTS_SOURCE="https://github.com/vozlt/nginx-module-vts/archive/master.zip"
ARG NGINX_PAGESPEED_AUTOBUILD_SCRIPT="https://raw.githubusercontent.com/pagespeed/ngx_pagespeed/master/scripts/build_ngx_pagespeed.sh"

RUN /bin/bash -c "                                                       \
   ### Define timezone (prevent installing interactions)             ### \
   echo Europe/London > /etc/timezone                                 && \
   ln -fs /usr/share/zoneinfo/Europe/London /etc/localtime            && \
   ### Installings for pre-build stage                               ### \
   apt-get update                                                     && \
   apt-get install wget nano less curl unzip sudo -y                  && \
   ### Pre-build stage                                               ### \
   mkdir -p ${BUILDROOT}/downloads                                       \
            ${BUILDROOT}/modules                                         \
            ${BUILDROOT}/build                                        && \
   wget -O ${BUILDROOT}/downloads/openssl.tar.gz ${OPENSSL_SOURCE}    && \
   wget -O ${BUILDROOT}/downloads/nginxvts.zip ${NGINXVTS_SOURCE}     && \
   wget -O ${BUILDROOT}/downloads/ngx_pagespeed.sh                       \
           ${NGINX_PAGESPEED_AUTOBUILD_SCRIPT}                        && \
   cat ${BUILDROOT}/downloads/openssl.tar.gz | gzip -d | tar -x       && \
   mv openssl-* ${BUILDROOT}/modules/openssl                          && \
   unzip ${BUILDROOT}/downloads/nginxvts.zip                          && \
   mv nginx-module-vts-master ${BUILDROOT}/modules/nginxvts           && \
   ### Build OpenSSL                                                 ### \
   cd ${BUILDROOT}/modules/openssl                                    && \
   apt-get install zlib1g ca-certificates gcc make perl libgeoip1        \
                   libz-dev openssl libssl-dev libgeoip-dev -y        && \
   ./Configure linux-x86_64 no-weak-ssl-ciphers                          \
               enable-ec_nistp_64_gcc_128                                \
               shared                                                    \
               --prefix=/usr                                             \
               --openssldir=/usr                                      && \
   make -j${BUILD_THREADCOUNT}                                        && \
   make -j${BUILD_THREADCOUNT} test                                   && \
   make -j${BUILD_THREADCOUNT} install_sw install_ssldirs             && \
   rm /usr/lib/x86_64-linux-gnu/libssl.so.1.1                            \
      /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1                      && \
   ln -sf /usr/lib/libcrypto.so.1.1                                      \
      /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1                      && \
   ln -sf /usr/lib/libssl.so.1.1                                         \
      /usr/lib/x86_64-linux-gnu/libssl.so.1.1                         && \
   openssl version                                                    && \
   ### Build nginx with all modules                                  ### \
   cd ${BUILDROOT}/build                                              && \
   chmod 700 ${BUILDROOT}/downloads/ngx_pagespeed.sh                  && \
   sed -i \"s/run\\ wget/run\\ wget\\ --no-check-certificate/g\"         \
         ${BUILDROOT}/downloads/ngx_pagespeed.sh                      && \
   ${BUILDROOT}/downloads/ngx_pagespeed.sh --assume-yes                  \
      --nginx-version ${NGINX_VERSION}                                   \
      --ngx-pagespeed-version ${PAGESPEED_VERSION}                       \
      --additional-nginx-configure-arguments=\"                          \
         --with-openssl=${BUILDROOT}/modules/openssl                     \
         --add-module=${BUILDROOT}/modules/nginxvts                      \
         --with-http_geoip_module                                        \
         --prefix=/etc/nginx                                             \
         --sbin-path=/usr/sbin/nginx                                     \
         --modules-path=/usr/lib/nginx/modules                           \
         --conf-path=/etc/nginx/nginx.conf                               \
         --error-log-path=/var/log/nginx/error.log                       \
         --http-log-path=/var/log/nginx/access.log                       \
         --pid-path=/var/run/nginx.pid                                   \
         --lock-path=/var/run/nginx.lock                                 \
         --http-client-body-temp-path=/var/cache/nginx/client_temp       \
         --http-proxy-temp-path=/var/cache/nginx/proxy_temp              \
         --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp          \
         --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp              \
         --http-scgi-temp-path=/var/cache/nginx/scgi_temp                \
         --user=nginx                                                    \
         --group=nginx                                                   \
         --with-compat                                                   \
         --with-file-aio                                                 \
         --with-threads                                                  \
         --with-http_addition_module                                     \
         --with-http_auth_request_module                                 \
         --with-http_dav_module                                          \
         --with-http_flv_module                                          \
         --with-http_gunzip_module                                       \
         --with-http_gzip_static_module                                  \
         --with-http_mp4_module                                          \
         --with-http_random_index_module                                 \
         --with-http_realip_module                                       \
         --with-http_secure_link_module                                  \
         --with-http_slice_module                                        \
         --with-http_ssl_module                                          \
         --with-http_stub_status_module                                  \
         --with-http_sub_module                                          \
         --with-http_v2_module                                           \
         --with-mail                                                     \
         --with-mail_ssl_module                                          \
         --with-stream                                                   \
         --with-stream_realip_module                                     \
         --with-stream_ssl_module                                        \
         --with-stream_ssl_preread_module                                \
         --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat         \
            -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC'       \
         --with-ld-opt='-Wl,-Bsymbolic-functions                         \
            -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie'\"           && \
   mkdir -p /var/cache/nginx                                          && \
   useradd nginx                                                      && \
   ### Purge unnecessary files and packages                          ### \
   rm -rf ${BUILDROOT}/downloads                                         \
          ${BUILDROOT}/modules                                           \
          /root/incubator-pagespeed-ngx*                                 \
          /root/nginx-*                                                  \
          ${BUILDROOT}/build                                          && \
   apt-get purge -y pinentry-gnome3 tor g++-multilib g++-7-multilib gcc  \
      gcc-7-doc libstdc++6-7-dbg parcimonie xloadimage scdaemon git bzr  \
      libstdc++-7-doc ed diffutils-doc pinentry-doc readline-doc perl    \
      build-essential dirmngr dpkg-dev fakeroot g++ g++-7 make libz-dev  \
      libalgorithm-diff-perl libassuan0 libdpkg-perl libfakeroot patch   \
      libksba8 libalgorithm-merge-perl libalgorithm-diff-xs-perl         \
      libgeoip-dev libfile-fcntllock-perl liblocale-gettext-perl         \
      libnpth0 libpcre16-3 libpcre3-dev libpcre32-3 libpcrecpp0v5        \
      libreadline7 libstdc++-7-dev pinentry-curses readline-common       \
      uuid-dev                                                        && \
   apt-get autoremove -y                                              && \
   apt-get clean -y                                                   && \
   apt-get autoclean -y                                               && \
   rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*"

CMD ["nginx", "-g", "daemon off;"]
