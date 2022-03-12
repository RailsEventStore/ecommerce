module.exports = (api) => {
  api.cache(true)
  return {
    presets: [
      [
        "@babel/preset-env",
        {
          modules: false,
          useBuiltIns: "entry",
          corejs: {
            version: 3,
          },
          targets: {
            browsers: [
              "> 1% in AU",
              "last 2 versions",
              "Firefox ESR",
              "not ie < 11",
              "iOS >= 8.4",
              "Safari >= 8",
              "Android >= 4.4",
            ],
          },
        },
      ],
      "@babel/preset-react",
    ],
    sourceType: "unambiguous",
  }
}
