FROM python:3.12-slim

# Install dependencies for compilation (e.g. psycopg2) and for cloning
# the private zing-core-common git dependency over SSH
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    curl \
    git \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
ENV POETRY_VERSION=2.1.0
RUN curl -sSL https://install.python-poetry.org | python3 - \
    && ln -s /root/.local/bin/poetry /usr/local/bin/poetry
ENV PATH="/root/.local/bin:$PATH"

WORKDIR /app

COPY pyproject.toml poetry.lock* ./

# Install dependencies. --mount=type=ssh consumes the SSH agent forwarded by
# `docker build --ssh default` so Poetry can clone the private zing-core-common git dep.
RUN --mount=type=ssh \
    mkdir -p -m 0700 ~/.ssh \
 && ssh-keyscan github.com >> ~/.ssh/known_hosts \
 && poetry config virtualenvs.create false \
 && poetry config installer.max-workers 1 \
 && poetry config requests.max-retries 5 \
 && (poetry install --no-root --only main --no-interaction --no-ansi || \
     (echo "First attempt failed, retrying..." && poetry install --no-root --only main --no-interaction --no-ansi))

# Copy whole project
COPY . .

# Add PYTHONPATH
ENV PYTHONPATH=/app
