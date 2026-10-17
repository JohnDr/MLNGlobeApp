#!/usr/bin/env python3
"""Static server for the harness plus POST /save?name=X -> /tmp/shots/X.png (used by ?save=NAME)."""
import http.server, os, urllib.parse

OUT = os.environ.get("SHOTS_DIR", "/tmp/shots")

class H(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        u = urllib.parse.urlparse(self.path)
        name = os.path.basename(urllib.parse.parse_qs(u.query).get("name", ["shot"])[0])
        data = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        os.makedirs(OUT, exist_ok=True)
        with open(os.path.join(OUT, name + ".png"), "wb") as f:
            f.write(data)
        self.send_response(200); self.send_header("Access-Control-Allow-Origin", "*"); self.end_headers()

if __name__ == "__main__":
    http.server.ThreadingHTTPServer(("127.0.0.1", 8765), H).serve_forever()
