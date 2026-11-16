#!/usr/bin/env python3
"""Single Page Application (SPA) HTTP Server for LearnTZ Web.

Rewrites all non-file route requests (e.g. /admin/dashboard, /account, etc.)
to /index.html so Flutter's client-side router handles navigation correctly.
"""

from __future__ import annotations

import http.server
import os
import socketserver
import sys

PORT = 5056
DIRECTORY = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "build", "web")


class SpaRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def send_head(self):
        # Resolve the requested path against the build/web directory
        full_path = self.translate_path(self.path)
        # If the target file or directory does not exist, serve index.html
        if not os.path.exists(full_path) or (
            os.path.isdir(full_path)
            and not os.path.exists(os.path.join(full_path, "index.html"))
        ):
            self.path = "/index.html"
        return super().send_head()

    def copyfile(self, source, outputfile):
        try:
            super().copyfile(source, outputfile)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def log_message(self, format, *args):
        # Concise logging
        sys.stderr.write(f"[{self.log_date_time_string()}] {format % args}\n")


def main():
    os.chdir(DIRECTORY)
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", PORT), SpaRequestHandler) as httpd:
        print(f"LearnTZ SPA Web Server serving {DIRECTORY} on http://localhost:{PORT}")
        sys.stdout.flush()
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()
