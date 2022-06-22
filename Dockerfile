FROM debian:bullseye-slim

ENV APPHOME /opt/ReadAlongsDesktop
ENV PORT 5000

# Install system dependencies, but keep results lean
RUN apt-get update \
    && apt-get install -y \
        python3 \
        python3-pip \
        git \
        libxml2 \
        libxml2-dev \
        python3-qtpy \
        ffmpeg \
        vim-nox \
    && apt-get clean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

# Install 3rd party dependencies in their own layer, for faster rebuilds when we
# change ReadAlong-Studio source code
# RUN python3 -m pip install gunicorn # Uncomment if you want to run production server
ADD requirements.txt $APPHOME/requirements.txt
RUN python3 -m pip install --upgrade pip \
    && python3 -m pip install gevent \
    && python3 -m pip install -r $APPHOME/requirements.txt

# We don't want Docker to cache the installation of g2p or Studio, so place them
# after COPY . $APPHOME, which almost invariable invalidates the cache.
COPY . $APPHOME
WORKDIR $APPHOME
# Get and install the latest g2p
RUN git clone https://github.com/roedoejet/g2p.git
RUN cd g2p && python3 -m pip install -e .
# Install ReadAlong-Studio itself
RUN git clone https://github.com/ReadAlongs/Studio.git
RUN cd Studio && python3 -m pip install -e .

# Run the default gui (on localhost:5000)
CMD python3 ./desktopApp.py

# For a production server, comment out the default gui CMD above, and run the
# gui using gunicorn instead:
# CMD gunicorn -k gevent -w 1 readalongs.app:app --bind 0.0.0.0:5000
