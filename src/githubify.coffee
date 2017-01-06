Bluebird = require "bluebird"
fs = require "fs-promise"
resolve = require("path").resolve
repoExists = require "./repoExists"
hostedGitInfo = require "hosted-git-info"
commandExists = Bluebird.promisify require "command-exists"
exec = require "faithful-exec"

module.exports = githubify = Bluebird.coroutine (cwd,log) ->
  log = console.log.bind(console) unless log?
  throw new Error "Cannot find git" unless yield commandExists "git"
  throw new Error "Cannot find gh. Please install with `npm install gh -g`" unless yield commandExists "gh"

  username = yield whoIsUser()
  throw new Error "Not logged in on Node GH. Login first with `gh user --login`" unless username
  log "Logged in on Node GH as #{username}."

  pjPath = resolve cwd, "package.json"
  throw new Error "Sorry, #{cwd} is not the root of a node.js package." unless fs.exists pjPath

  pkgData = require pjPath
  packageName = pkgData.name
  throw new Error "Package does not have a package name" unless packageName

  unless pkgData.repository
    repoURL = hostedGitInfo.fromUrl("#{username}/#{packageName}").ssh()
    log "No repository specified in package.json."
    log "Setting repository url to #{repoURL}."
    pkgData.name
    pkgData.repository =
      type: "git"
      url: repoURL
    log "Updating #{pjPath}."
    yield fs.writeFile pjPath, JSON.stringify pkgData, null, 2

  throw new Error "Repository type was #{pkgData.repository.type}, not git." unless pkgData.repository.type is "git"
  throw new Error "No repository url" unless pkgData.repository.url
  repoInfo = hostedGitInfo.fromUrl pkgData.repository.url
  throw new Error "Invalid repository url" unless repoInfo
  throw new Error "Only github urls are supported" unless repoInfo.type is "github"

  if yield repoExists repoInfo.path()
    log "Repository #{repoInfo.path()} already exists on Github."
  else
    orgBit = ""
    if repoInfo.user isnt username
      log "Base name in Github url (#{repoInfo.user}) is different than current GH
          user (#{username}). Assuming that #{repoInfo.user} is an organization."
      orgBit = " --organization #{repoInfo.user}"
    log "Creating #{repoInfo.path()} on Github."
    yield exec "gh repo --new #{repoInfo.project} --description '#{pkgData.description}'" + orgBit

  goodGitDir = try Boolean(yield exec "git status") catch err then false
  if goodGitDir
    log "#{cwd} is already a git working directory. Setting remote orgin to #{repoInfo.ssh()}."
    yield exec "git remote remove origin"
    yield exec "git remote add origin -u #{repoInfo.ssh()}"
  else
    # Most likely there's simply nothing under .git
    throw new Error "Your git repository may be corrupted." if yield fs.exists resolve cwd, ".git"
    log " #{cwd} is not a git working directory."
    log "Initializing new git repository in #{cwd}"
    yield exec "git init"
    log "Adding all files and making initial commit."
    yield exec "git add ."
    yield exec "git commit -m 'Initial commit. (by GitHubify)'"
    log "Setting remote origin to #{repoInfo.ssh()}"
    yield exec "git remote add origin #{repoInfo.ssh()}"
    log "Pushing branch master to Github"
    yield exec "git push -u origin master"

whoIsUser = Bluebird.coroutine ->
  {stdout} = yield exec "gh user --whoami"
  throw new Error "Nothing on stdout" unless stdout
  stdout.trim()
