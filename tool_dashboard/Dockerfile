FROM python:3.12-slim

ENV PORT=8501

WORKDIR /tmp

# Set /app writeable by all users to allow running as non-root (e.g. with securityContext.runAsUser: 65534 in Kubernetes).
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libmariadb-dev \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY . /app/

RUN pip3 install --no-cache-dir --no-compile -r /app/requirements.txt

EXPOSE ${PORT}

HEALTHCHECK CMD curl --fail http://localhost:${PORT}/_stcore/health

ENTRYPOINT /bin/bash /app/run_dashboard.sh --port ${PORT} --streamlit-path streamlit
