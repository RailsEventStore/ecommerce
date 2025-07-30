import { WebpackManifestPlugin } from "webpack-manifest-plugin"
import cssnano from "cssnano"
import glob from "glob"
import MiniCssExtractPlugin from "mini-css-extract-plugin"
import path from "path"
import postcssImport from "postcss-import"
import postcssPresetEnv from "postcss-preset-env"
import postcssUrl from "postcss-url"
const postcssCssVariables = require("postcss-css-variables")

const cssLoaders = (
  mode: string,
  modules: Record<string, unknown> | boolean
): (string | object)[] => [
  MiniCssExtractPlugin.loader,
  {
    loader: "css-loader",
    options: { importLoaders: 1, modules },
  },
  {
    loader: "postcss-loader",
    options: {
      postcssOptions: {
        plugins: [
          // Add module-like @import support to our CSS. This sets the context for all imports
          // to be the base entry point.
          postcssImport,
          // postcss-url "rebases" any `url()` references in CSS to their original relative
          // position on the filesystem (so that postcss-import doesn't break things)
          postcssUrl(),
          // Make variables available to CSS compilation
          // NOTE: This plugin expects all variables to be defined in either:
          // - The original CSS
          // - The `variables` object we’re passing it
          // If things are missing from there they’ll be resolved as `undefined`
          postcssCssVariables({
            variables: {},
          }),
          // Polyfill
          postcssPresetEnv({ stage: 1 }),
          mode === "production" ? cssnano({ preset: "default" }) : null,
        ].filter((plugin) => plugin),
      },
    },
  },
]

export const config = (mode: string): Record<string, unknown> => ({
  devtool: mode === "production" ? undefined : "cheap-module-source-map",
  // Find the entry points for each slice and create a set of entries with a
  // consistent naming convention so we can easily reference in templates:
  // `${sliceName}__${entryName}`
  entry: glob
    // We expect that the asset will exist at /:slice/assets/:entry
    .sync(`${path.join(__dirname, "../slices")}/*`)
    .map((dir: string) =>
      glob.sync(`${dir}/**/entry.{js,jsx,ts,tsx}`).map((entry) => {
        const entryName = entry.includes("/assets/")
          ? entry.split(`${dir}/assets/`).slice(-1)[0].split("/entry.")[0]
          : path.basename(path.dirname(entry))
        return [`${path.basename(dir)}/${entryName}`, entry]
      })
    )
    // Flatten
    .reduce((a, b) => a.concat(b), [])
    // Turn into `entry` object
    .reduce((output: Record<string, unknown>, entry) => {
      const [name, location] = entry
      output[name] = [location]
      return output
    }, {}),
  mode,
  module: {
    rules: [
      // Use babel for *anything* matching *.es.js, including within
      // other dependencies in node_modules.
      {
        exclude: /node_modules/,
        test: /.*(?<!\.test)\.tsx?$/,
        use: "ts-loader",
      },
      {
        loader: "babel-loader",
        test: /.*(?<!\.test)\.es\.js$/,
      },
      {
        loader: "babel-loader",
        test: /.*(?<!\.test)\.esm\.js$/,
      },
      {
        exclude: /\/test\/$/i,
        loader: "babel-loader",
        test: /.*(?<!\.test)\.js$/,
      },
      {
        exclude: /\/test\/$/i,
        loader: "file-loader",
        options: { name: "[path][name].[ext]" },
        test: /\.(png|jpe?g|gif|svg|woff2?|eot|ttf|mp3|mp4|webm|webp|mp4|m4v|pdf)$/,
      },
      {
        exclude: /\/components\/.+\.s?css$/i,
        test: /\.s?css$/i,
        use: cssLoaders(mode, false),
      },
      {
        test: /\/components\/.+\.s?css$/i,
        use: cssLoaders(mode, { localIdentName: "[path][name]__[local]" }),
      },
      {
        test: /\.ya?ml$/,
        type: "json",
        use: "yaml-loader",
      },
    ],
  },
  optimization: {
    usedExports: true,
  },
  output: {
    filename: mode === "development" ? "[name].js" : "[name].[contenthash].js",
    path:
      mode === "development"
        ? path.resolve(__dirname, "tmp/assets")
        : path.resolve(__dirname, "..", "public/assets"),
    publicPath:
      mode === "development"
        ? `http://localhost:${process.env.PORT}/assets/`
        : "/assets/",
  },
  resolve: {
    alias: {},
    extensions: [".tsx", ".ts", ".js"],
    mainFields: ["module", "main"],
  },
  plugins: [
    new MiniCssExtractPlugin({
      chunkFilename: "[name].[contenthash].css",
      filename:
        mode === "development" ? "[name].css" : "[name].[contenthash].css",
      ignoreOrder: false,
    }),
    new WebpackManifestPlugin({ fileName: "manifest.json" }),
  ],
})
