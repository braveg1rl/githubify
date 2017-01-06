githubify = require "./githubify"

module.exports = run = ->
  githubify(process.cwd())
    .then ->
      process.exit 0
    .then null, (err) ->
      console.error err
      process.exit 1
