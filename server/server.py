from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs
from pathlib import Path
import configparser
import html

ROOT = Path(__file__).resolve().parent
CONFIG = ROOT / "config.ini"
HOST = "0.0.0.0"
PORT = 8765


def read_config():
    cfg = configparser.ConfigParser(interpolation=None)
    cfg.optionxform = str
    cfg.read(CONFIG, encoding="utf-8-sig")
    return cfg


def write_config(cfg):
    with CONFIG.open("w", encoding="utf-8-sig") as f:
        cfg.write(f, space_around_delimiters=False)


def page():
    cfg = read_config()
    g = cfg["General"]
    s = cfg["Special"]
    special = "checked" if s.get("Enabled", "0") == "1" else ""
    games = "checked" if g.get("GamesEnabled", "1") == "1" else ""

    return f'''<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Painel Modo Aluno</title>
<style>
*{{box-sizing:border-box}}
body{{font-family:system-ui,Segoe UI,sans-serif;background:#11151a;color:#fff;margin:0;padding:32px}}
main{{max-width:720px;margin:auto;background:#1d232b;padding:28px;border-radius:22px}}
h1{{margin-top:0}}
label{{display:block;margin:18px 0 6px;font-weight:700}}
input[type=text],input[type=url]{{width:100%;padding:14px;border-radius:10px;border:1px solid #46505d;background:#101419;color:white;font-size:16px}}
.row{{display:flex;gap:12px;align-items:center;margin:18px 0}}
.row input{{width:22px;height:22px}}
button{{border:0;border-radius:12px;padding:15px 22px;font-size:17px;font-weight:800;cursor:pointer}}
small{{color:#aab3bf}} code{{background:#0d1116;padding:3px 6px;border-radius:5px}}
</style>
</head>
<body><main>
<h1>Modo Aluno — Painel</h1>
<p>Config atual: <strong>v{html.escape(g.get("Version", "0"))}</strong></p>
<form method="post" action="/api/save">
<div class="row"><input id="special" type="checkbox" name="special_enabled" value="1" {special}><label for="special" style="margin:0">Mostrar botão especial / prova</label></div>
<label>Texto do botão</label>
<input type="text" name="special_name" value="{html.escape(s.get("Name", "FAZER PROVA"))}">
<label>URL da prova</label>
<input type="url" name="special_target" value="{html.escape(s.get("Target", "https://example.com/prova"))}">
<div class="row"><input id="games" type="checkbox" name="games_enabled" value="1" {games}><label for="games" style="margin:0">Mostrar aba Jogos</label></div>
<button type="submit">SALVAR E PUBLICAR</button>
</form>
<p><small>Cada salvamento aumenta a versão. Os launchers consultam <code>/config.ini</code> automaticamente.</small></p>
<p><small>Protótipo sem login: use só na rede local.</small></p>
</main></body></html>'''


class Handler(BaseHTTPRequestHandler):
    def send_bytes(self, body, content_type="text/html; charset=utf-8", status=200):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path in ("/", "/admin"):
            self.send_bytes(page().encode("utf-8"))
            return
        if self.path == "/config.ini":
            if not CONFIG.exists():
                self.send_bytes(b"config missing", "text/plain; charset=utf-8", 404)
                return
            self.send_bytes(CONFIG.read_bytes(), "text/plain; charset=utf-8")
            return
        self.send_bytes(b"not found", "text/plain; charset=utf-8", 404)

    def do_POST(self):
        if self.path != "/api/save":
            self.send_bytes(b"not found", "text/plain; charset=utf-8", 404)
            return

        length = int(self.headers.get("Content-Length", "0"))
        data = parse_qs(self.rfile.read(length).decode("utf-8"))
        cfg = read_config()

        cfg["Special"]["Enabled"] = "1" if "special_enabled" in data else "0"
        cfg["Special"]["Name"] = data.get("special_name", ["FAZER PROVA"])[0].strip() or "FAZER PROVA"
        cfg["Special"]["Target"] = data.get("special_target", ["https://example.com/prova"])[0].strip()
        cfg["General"]["GamesEnabled"] = "1" if "games_enabled" in data else "0"

        try:
            version = int(cfg["General"].get("Version", "0"))
        except ValueError:
            version = 0
        cfg["General"]["Version"] = str(version + 1)
        write_config(cfg)

        self.send_response(303)
        self.send_header("Location", "/admin")
        self.end_headers()

    def log_message(self, fmt, *args):
        print("[%s] %s" % (self.address_string(), fmt % args))


if __name__ == "__main__":
    print("=" * 46)
    print(" MODO ALUNO - SERVIDOR DE TESTE")
    print("=" * 46)
    print(f" Painel: http://127.0.0.1:{PORT}/admin")
    print(f" Config: http://127.0.0.1:{PORT}/config.ini")
    print(" Para outros PCs, use o IPv4 deste PC.")
    print(" CTRL+C encerra.")
    print("=" * 46)
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
