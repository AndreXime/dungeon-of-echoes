#!/usr/bin/env python3
"""Serve a Godot web export. Use --coop for multithreaded builds (SharedArrayBuffer)."""

from __future__ import annotations

import argparse
import functools
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class Handler(SimpleHTTPRequestHandler):
	coop: bool = False

	def end_headers(self) -> None:
		if self.coop:
			self.send_header("Cross-Origin-Opener-Policy", "same-origin")
			self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
		super().end_headers()


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("root", type=Path, help="Pasta da build (com index.html)")
	parser.add_argument("--port", type=int, default=8080)
	parser.add_argument(
		"--coop",
		action="store_true",
		help="Envia COOP/COEP (necessário para Web multi / threads)",
	)
	args = parser.parse_args()
	root = args.root.resolve()
	if not (root / "index.html").is_file():
		raise SystemExit(f"Sem index.html em {root}")

	handler = functools.partial(Handler, directory=str(root))
	Handler.coop = args.coop
	server = ThreadingHTTPServer(("127.0.0.1", args.port), handler)
	mode = "multi (COOP/COEP)" if args.coop else "single"
	print(f"Servindo {root} em http://127.0.0.1:{args.port}/  [{mode}]")
	server.serve_forever()


if __name__ == "__main__":
	main()
