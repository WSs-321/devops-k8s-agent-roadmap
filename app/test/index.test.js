const test = require("node:test");
const assert = require("node:assert/strict");

const { add, greet } = require("../src/index");

test("add returns the sum of two numbers", () => {
  assert.equal(add(1, 2), 3);
  assert.equal(add(-1, 1), 0);
});

test("greet returns a greeting with the provided name", () => {
  assert.equal(greet("alice"), "hello, alice!");
});

test("greet falls back to world when no name is provided", () => {
  assert.equal(greet(), "hello, world!");
});
