FROM scratch

# Metadata params
ARG BUILD_DATE
ARG VERSION
ARG VCS_URL
ARG VCS_REF
ARG TARBALL
ARG RELEASE_DESCRIPTION

# https://github.com/opencontainers/image-spec/blob/master/annotations.md
LABEL org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.source="$VCS_URL" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.vendor='FrangaL' \
      org.opencontainers.image.version="$VERSION" \
      org.opencontainers.image.title="Debian slim ($RELEASE_DESCRIPTION release)" \
      org.opencontainers.image.description="Debian slim $RELEASE_DESCRIPTION" \
      org.opencontainers.image.url='https://muriana.pro' \
      org.opencontainers.image.authors="FrangaL <frangal@gmail.com>"

ADD $TARBALL /

RUN echo 'debconf debconf/frontend select teletype' | debconf-set-selections

CMD ["bash"]
