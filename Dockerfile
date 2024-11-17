# Stage 1: Base Image
FROM python:3.11-bookworm AS base

# Combine Salt installation steps
RUN apt-get update && apt-get install -y \
    curl \
    gcc \
    libffi-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir salt==3006 \
    && mkdir -p /etc/salt /var/cache/salt /var/log/salt /var/run/salt

# Stage 2: App Image
FROM python:3.11-slim-bookworm AS app

# Copy Salt binaries and dependencies from base
COPY --from=base /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=base /usr/local/bin/salt* /usr/local/bin/

# Copy local Salt configurations and states
COPY ./salt/master/top.sls /etc/salt/master
COPY ./salt/minion/top.sls /etc/salt/minion
COPY ./salt/states /srv/salt

# Combine directory creation into COPY
RUN mkdir -p /var/cache/salt /var/log/salt /var/run/salt

# Expose Salt API port
EXPOSE 8000

# Start Salt services
CMD ["sh", "-c", "salt-master -d && salt-minion -d && salt-syndic -d && salt-api -d"]