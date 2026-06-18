const baseUrl = process.env.SMOKE_BASE_URL || "http://localhost:3000";

async function check(path, predicate) {
  const url = `${baseUrl}${path}`;
  const res = await fetch(url, { redirect: "manual" });
  const body = res.headers.get("content-type")?.includes("json")
    ? await res.json()
    : await res.text();
  if (!predicate(res, body)) {
    throw new Error(`Fallo smoke en ${url}`);
  }
  console.log("OK", url);
}

async function main() {
  await check("/api/health", (res, body) => res.status === 200 && body.ok === true);
  await check("/", (res) => res.status === 200 || res.status === 307);
  await check("/login", (res) => res.status === 200);
  await check("/images/logo.png", (res) => res.status === 200);
  await check("/images/parent_app_mockup.png", (res) => res.status === 200);
  await check("/dashboard", (res) => res.status === 307 || res.status === 302);
  console.log("Smoke deploy completado");
}

main().catch((error) => {
  console.error("Smoke deploy fallo:", error.message);
  process.exit(1);
});