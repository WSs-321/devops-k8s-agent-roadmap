function add(a, b) {
  return a + b;
}

function greet(name = "roadmap") {
  return `hello, ${name}!`;
}

if (require.main === module) {
  console.log(greet("devops-k8s-agent-roadmap"));
  console.log(`1 + 2 = ${add(1, 2)}`);
}

module.exports = { add, greet };
