// Automatically polyfill based on browserlists configuration in babel.config
import "core-js/stable"

// Import base JS/CSS definitions
import "./index.ts"
import "./index.css"

// This will inspect all subdirectories from the context (this file) and
// require files matching the regex.
// https://webpack.js.org/guides/dependency-management/#require-context
require.context(
  ".",
  true,
  /^\.\/.*\.(jpe?g|png|gif|svg|woff2?|ttf|otf|eot|ico|mp4|m4v|pdf)$/
)
