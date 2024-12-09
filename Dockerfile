FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    python3-dev \
    python3-venv \
    ruby \
    ruby-dev \
    rubygems \
    ruby-bundler \
    build-essential \
    libgdal-dev \
    libxml2-dev \
    git \
    gdal-bin \
    python3-gdal \
    python3-scipy \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN git clone https://github.com/UNopenGIS/gmldem2tif.git \
    && cd gmldem2tif \
    && bundle install

RUN git clone https://github.com/mapbox/mbutil.git \
    && cd mbutil \
    && python3 setup.py install

RUN git clone https://github.com/mapbox/rio-rgbify.git \
    && cd rio-rgbify \
    && pip3 install -e '.[test]' --break-system-packages

RUN git clone https://github.com/smellman/rio-terrarium.git \
    && cd rio-terrarium \
    && pip3 install -e '.[test]' --break-system-packages

RUN git clone https://github.com/smellman/rio-gsidem.git \
    && cd rio-gsidem \
    && pip3 install -e '.[test]' --break-system-packages

RUN git clone https://github.com/qchizu/gdal2NPtiles.git \
    && cd gdal2NPtiles \
    && cp gdal2NPtiles.py /usr/local/bin/ \
    && chmod +x /usr/local/bin/gdal2NPtiles.py

COPY docker_entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker_entrypoint.sh
ENTRYPOINT [ "/usr/local/bin/docker_entrypoint.sh" ]
