const fs = require("node:fs");
const path = require("node:path");

const projectRoot = path.resolve(__dirname, "..");
const srcDir = path.join(projectRoot, "src");
const distDir = path.join(projectRoot, "dist");

const mode = process.argv.includes("--mode=ci") ? "ci" : "production";

function clean(target) {
  if (fs.existsSync(target)) {
    fs.rmSync(target, { recursive: true, force: true });
  }
}

function copySources() {
  fs.mkdirSync(distDir, { recursive: true });
  fs.cpSync(srcDir, distDir, { recursive: true });
}

function writeBuildInfo() {
  const info = {
    builtAt: new Date().toISOString(),
    nodeVersion: process.version,
    platform: process.platform,
    mode,
  };
  fs.writeFileSync(
    path.join(distDir, "build-info.json"),
    JSON.stringify(info, null, 2),
    "utf8"
  );
}

clean(distDir);
copySources();
writeBuildInfo();

console.log(`build done (${mode}) -> ${distDir}`);
