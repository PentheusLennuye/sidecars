# ┌─ Sidecars ────────────────────────────────────────────────────────────────────────────────────┐
# │                                                                                               │
# │ A Dockerfile for Python services                                                              │
# │                                                                                               │
# └───────────────────────────────────────────────────────────────────────────────────────────────┘

# BASE IMAGE ─────────────────────────────────────────────────────────────────────────────────────

ARG ALPINE_VER=3.23
ARG PYTHON_VER=3.13
FROM python:${PYTHON_VER}-alpine${ALPINE_VER} AS build-image

# UPDATES and BINARIES ───────────────────────────────────────────────────────────────────────────
RUN apk --update --no-progress --no-cache upgrade
RUN apk --no-progress --no-cache add git
RUN apk --no-progress --virtual .build-deps add pipx

# PYTHON DEPENDENCIES ────────────────────────────────────────────────────────────────────────────

## Create requirements.txt and install dependencies in container root

ENV PATH="/root/.local/bin:$PATH"
WORKDIR /app
RUN pipx install poetry
COPY poetry.lock pyproject.toml ./
RUN poetry config virtualenvs.create false && poetry self add poetry-plugin-export
RUN poetry export --output=requirements.txt && python -m pip install -r requirements.txt

# CLEANUP ────────────────────────────────────────────────────────────────────────────────────────
RUN apk del .build-deps && rm poetry.lock requirements.txt

# ┌─ Sidecars ────────────────────────────────────────────────────────────────────────────────────┐
# │                                                                                               │
# │ Deployment Image                                                                              │
# │                                                                                               │
# └───────────────────────────────────────────────────────────────────────────────────────────────┘

FROM python:${PYTHON_VER}-alpine${ALPINE_VER}
ARG PYTHON_VER=3.13
ARG USERID=1000
ARG RUNGROUP=appgroup
ARG RUNUSER=appuser
ARG PYTHON_DIR=/usr/local/lib/python${PYTHON_VER}

# Install dependencies ───────────────────────────────────────────────────────────────────────────

# Binaries
COPY --from=build-image /usr/local/bin/ /usr/local/bin/

# Python packages
COPY --from=build-image ${PYTHON_DIR}/site-packages/ ${PYTHON_DIR}/site-packages/

# Install App and clean up ───────────────────────────────────────────────────────────────────────
COPY src /app
RUN find /app -name __pycache -exec rm -rf {} \;

# ┌───────────────────────────────────────────────────────────────────────────────────────────────┐
# │ SECURE RUN                                                                                    │
# └───────────────────────────────────────────────────────────────────────────────────────────────┘

RUN addgroup -S ${RUNGROUP} && adduser -G ${RUNGROUP} -S ${RUNUSER} -u ${USERID}
RUN ([ -d tests ] || mkdir tests)
USER ${RUNUSER}
ENV PATH="/home/${RUNUSER}/.local/bin:$PATH"

CMD ["/app/sidecars/sidecars.py"]

