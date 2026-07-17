FROM python:3.12-slim

# Set environment variables for Streamlit configuration
ENV STREAMLIT_SERVER_PORT=8501

# nobody (uid 65534) has HOME=/nonexistent on Debian; set HOME to a writable
# directory so Streamlit can write its ~/.streamlit data files.
ENV HOME=/tmp

WORKDIR /tmp

# Set /app writeable by all users to allow running as non-root (e.g. with securityContext.runAsUser: 65534 in Kubernetes).
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libmariadb-dev \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY . /app/

RUN pip3 install --no-cache-dir --no-compile -r /app/requirements.txt

EXPOSE ${STREAMLIT_SERVER_PORT}

HEALTHCHECK CMD curl --fail http://localhost:${STREAMLIT_SERVER_PORT}/_stcore/health

# run_dashboard.sh will fail to poll healthcheck at the moment, so we directly run the streamlit command here.
# In the future, if we want to add more complex healthcheck-based restart logic, we can switch back to using
# run_dashboard.sh as the entrypoint.
ENTRYPOINT ["streamlit", "run", "--server.headless", "true", "/app/CBF_tool_page.py"]
