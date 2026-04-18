FROM python:3.12-slim

ENV PORT=8501

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libmariadb-dev \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY . .

RUN pip3 install --no-cache-dir --no-compile -r requirements.txt

EXPOSE ${PORT}

HEALTHCHECK CMD curl --fail http://localhost:${PORT}/_stcore/health

ENTRYPOINT streamlit run CBF_tool_page.py --server.port=${PORT} --server.address=0.0.0.0
