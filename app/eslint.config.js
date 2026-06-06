const js = require("@eslint/js");

module.exports = [
  // 1. 启用官方推荐规则
  js.configs.recommended,

  // 2. 项目通用设置
  {
    files: ["**/*.js"],
    languageOptions: {
      ecmaVersion: 2024,          // 支持到 ES2024 语法
      sourceType: "commonjs",     // 你的代码用的是 require/module.exports
      globals: {
        // CommonJS 全局变量声明（不声明会报 no-undef）
        require: "readonly",
        module: "readonly",
        __dirname: "readonly",
        __filename: "readonly",
        process: "readonly",
        console: "readonly",
        Buffer: "readonly",
      },
    },
  },
];