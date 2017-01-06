childProcess = require "child_process"
childProcess.exec = (cmd, options, next) ->
  next = options if typeof options is "function"
  setImmediate ->
    stdout = if execResults[cmd]? then execResults[cmd] else ""
    next null, stdout, ""

githubify = require "../lib/githubify"
resolve = require("path").resolve
Bluebird = require "bluebird"

log = (msg) ->

it "runs", ->
  githubify resolve(__dirname, "../"), log

execResults =
  "command -v git 2>/dev/null && { echo >&1 'git found'; exit 0; }": "/usrbin/git"
  "command -v gh 2>/dev/null && { echo >&1 'gh found'; exit 0; }": "/usr/local/bin/gh"
  "gh user --whoami": "braveg1rl\n"
  "gh repo --list": "braveg1rl/githubify\n"
