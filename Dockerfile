# Frappe LMS - Railway deployment Dockerfile
#
# This bypasses Railpack, which does not support this repo's monorepo layout
# (Python/Frappe backend defined via pyproject.toml + a separate Node/Vue
# frontend in /frontend that needs to be built and copied into
# lms/public/frontend).
#
# NOTE: This is a minimal build that gets the image building and deployable
# on Railway. The start command below is a placeholder - a real Frappe site
# needs a bench install + gunicorn/socketio/worker processes, which is out of
# scope for this fix.

FROM python:3.10-slim

WORKDIR /app

# System dependencies:
# - git, curl: needed by frappe/bench tooling and general fetching
# - nodejs/npm (and yarn via npm): needed to build the frontend
# - libxml2-dev, libxslt1-dev: required by lxml (see pyproject.toml)
# - build-essential: needed to compile Python packages with native extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    build-essential \
    libxml2-dev \
    libxslt1-dev \
    nodejs \
    npm \
    && npm install -g yarn \
    && rm -rf /var/lib/apt/lists/*

# Install Node/frontend dependencies first (leverages Docker layer caching)
COPY package.json ./
COPY frontend/package.json frontend/package.json

RUN npm install --ignore-scripts && npm run postinstall

# Install Python dependencies
COPY pyproject.toml ./
RUN pip install --no-cache-dir .

# Copy the rest of the source
COPY . .

# Build the frontend (outputs to lms/public/frontend per pyproject.toml [tool.bench.assets])
RUN cd frontend && yarn build

EXPOSE 8000

# Placeholder start command. Replace with the real Frappe/bench start command
# (e.g. bench serve / gunicorn) once the site setup is configured on Railway.
CMD ["python", "-m", "http.server", "8000"]
