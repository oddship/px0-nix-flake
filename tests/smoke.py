"""Exercise the installed binary, embedded UI, and local repository API."""
import json
import gzip
import os
import pathlib
import re
import subprocess
import sys
import tempfile
import time
import urllib.request

binary = sys.argv[1]
assert re.fullmatch(r"px0 \d+\.\d+\.\d+ \(.+\)\n", subprocess.check_output([binary, "-version"], text=True))
update = subprocess.run([binary, "-update"], capture_output=True, text=True)
assert update.returncode != 0 and "managed by Nix" in update.stderr
with tempfile.TemporaryDirectory() as root:
    pathlib.Path(root, "hello.txt").write_text("hello px0\n")
    with tempfile.TemporaryFile(mode="w+") as log:
        process = subprocess.Popen([binary, "-no-open", "-no-lsp", "-no-agent", "-no-telemetry", "-no-color", "-port", "0", root], stdout=log, stderr=log)
        try:
            deadline = time.monotonic() + 20
            address = None
            while time.monotonic() < deadline:
                log.seek(0)
                output = log.read()
                match = re.search(r"http://127\.0\.0\.1:\d+", output)
                if match:
                    address = match[0]
                    break
                if process.poll() is not None:
                    raise AssertionError(output)
                time.sleep(0.1)
            assert address, output
            def get(path):
                with urllib.request.urlopen(address + path, timeout=5) as response:
                    assert response.status == 200
                    return response.read()
            assert b"app.js" in get("/")
            assert len(get("/static/app.js")) > 10000
            mermaid_path = "/static/vendor/mermaid-12.0.0.min.js"
            assert b"mermaid" in get(mermaid_path)
            request = urllib.request.Request(address + mermaid_path, headers={"Accept-Encoding": "gzip"})
            with urllib.request.urlopen(request, timeout=5) as response:
                assert response.status == 200
                assert response.headers["Content-Encoding"] == "gzip"
                assert b"mermaid" in gzip.decompress(response.read())
            assert b"hello.txt" in get("/api/tree")
            assert isinstance(json.loads(get("/api/meta")), dict)
            print("px0 version, Nix update guard, UI and Mermaid assets, and repository API passed")
        finally:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
