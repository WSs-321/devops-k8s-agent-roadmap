function add(a, b) {
  return a + b;
}

function greet(name = "roadmap") {
  return `hello, ${name}!`;
}

if (require.main === module) {
  const http = require("node:http");
  const port = process.env.PORT || 3000;
  const server = http.createServer((req, res) => {
    if (req.url === "/health") {
      res.statusCode = 200;
      res.setHeader("Content-Type", "text/plain");
      res.end("OK");
      return;
    }
    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end(greet(process.env.GREETING));
  });
  server.listen(port, () => {
    console.log(`Server running at http://localhost:${port}/`);
  });
}

module.exports = { add, greet: (name = process.env.GREETING) => greet(name) };
