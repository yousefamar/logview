``#!/usr/bin/env node``

require! {
  fs
  path
  url
  electron: { app, BrowserWindow }
}

err, views <-! fs.readdir path.join __dirname, \views

throw err if err?

views .= filter -> it.ends-with \html
views .= map    -> it.split \. .[0]

cmd  = process.argv[2]
cmds = [ \ls ].concat views

unless cmds.includes cmd
  console.error "Usage: #{process.argv[1]} (#{cmds.join ' | '})"
  return

if cmd is \ls
  views.for-each !-> console.log it
  app.quit!
  return

var window

process.stdin.setEncoding \utf8

log = []
end = false
buffer = ''
process.stdin.on \readable ->
  chunk = process.stdin.read!

  return unless chunk?

  buffer += chunk

  while ~buffer.index-of \\n
    buffer .= split \\n
    # TODO: Handle malformed input
    buffer.shift! |> JSON.parse |> log.push
    window.web-contents.send \entry log[log.length - 1]
    buffer .= join \\n

process.stdin.on \end !->
  end := true
  window.web-contents.send \end

create-window = !->
  window := new BrowserWindow!
    ..web-contents.on \did-finish-load !->
      log.for-each -> window.web-contents.send \entry it
    ..load-URL url.format do
      pathname: path.join __dirname, \views, "#cmd.html"
      protocol: \file:
      slashes:  true
    ..on \closed !->
      window := null
    ..set-menu null
    ..web-contents.open-dev-tools!

app
  ..on \ready create-window
  ..on \window-all-closed !-> app.quit! if process.platform !== \darwin
  ..on \activate !-> create-window! unless window?
