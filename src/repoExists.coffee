Bluebird = require "bluebird"
fs = require "fs-promise"
exec = require "faithful-exec"

module.exports = Bluebird.coroutine (repoPath) ->
  {stdout} = yield exec "gh repo --list"
  throw new Error "Nothing on stdout for `gh repo --list`" unless stdout
  (return true if repo is repoPath) for repo in stdout.split "\n"
  return false
