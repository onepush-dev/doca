// Railway's healthcheck sends its own Host header; Doca answers 421 for any host other than
// DOCA_ORIGIN. Let only GET /health and GET /live (read-only status probes) through.
import { readFileSync, writeFileSync } from "node:fs";
const f = "apps/server/src/app/create-app.ts";
let s = readFileSync(f, "utf8");
const a = `      req.headers.host?.toLowerCase() !== origin.host.toLowerCase()
    )
      fail(421, "访问地址与服务配置不符");`;
if (!s.includes(a)) { console.error("patch anchor not found"); process.exit(1); }
s = s.replace(a, `      req.headers.host?.toLowerCase() !== origin.host.toLowerCase()
    ) {
      if (!(req.method === "GET" && (req.url === "/health" || req.url === "/live")))
        fail(421, "访问地址与服务配置不符");
    }`);
writeFileSync(f, s);
console.log("patched", f);
