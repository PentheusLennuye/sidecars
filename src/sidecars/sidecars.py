#!/usr/bin/env python3
"""Sidecars

sidecars.py Copyright 2026 George Cummings

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in
compliance with the License.

You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License
is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied. See the License for the specific language governing permissions and limitations under the
License.

"""

import logging
import logging.handlers
import socket
import time
from dataclasses import dataclass

LOG_HOST = "127.0.0.1"
LOG_PORT = 514


@dataclass
class Settings:
    """The system configuration."""

    debug: bool = True


settings = Settings()


def get_format(rfc: str) -> str:
    """Return a well-formed syslog string."""
    hostname = socket.getfqdn()
    rfc3164 = (
        r"%(asctime)s.%(msecs)03d "
        + f"{hostname:.15}"
        + r" %(name)s[%(process)s]: [%(levelname)s] %(message)s"
    )

    version = "1"

    rfc5424 = (
        version
        + r" %(asctime)s.%(msecs)03dZ"
        + f" {hostname:.15}"
        + r" %(name)s %(process)d ID%(levelno)s"
        + r" - %(levelname)s %(message)s "
    )

    return {"rfc3164": rfc3164, "rfc5424": rfc5424}[rfc]


def get_date_format(rfc: str) -> str:
    """Return a well-formed syslog string."""

    rfc3164 = "%Y-%m-%d %H:%M:%S"
    rfc5424 = "%Y-%m-%dT%H:%M:%S"

    return {"rfc3164": rfc3164, "rfc5424": rfc5424}[rfc]


def get_logger(app_name: str, environ: str, stream: str = "stderr") -> logging.Logger:
    """Return a formatted, streaming non-root logger."""

    def stderr() -> logging.StreamHandler:
        """Return a logging to console stderr."""
        return logging.StreamHandler()

    def syslog() -> logging.handlers.SysLogHandler:
        """Send logs over syslog UDP."""
        return logging.handlers.SysLogHandler(address=(LOG_HOST, LOG_PORT))

    logger = logging.getLogger(app_name)
    logger.setLevel(getattr(logging, "DEBUG" if settings.debug else "INFO"))
    handler = {"stderr": stderr, "syslog": syslog}[stream]()
    handler.append_nul = False  # modern syslog/fluentd does not need it.
    handler.setFormatter(
        logging.Formatter(
            get_format("rfc5424") + f" [{environ}]", datefmt=get_date_format("rfc5424")
        )
    )
    logger.addHandler(handler)

    return logger


if __name__ == "__main__":
    top_logger = get_logger("sidecar_test", "dev", "syslog")
    while True:
        top_logger.info("ping")
        time.sleep(5)
