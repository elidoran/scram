#!/usr/bin/env coffee

# scram will accept a script name and run it providing the specified options
# for scram to have its own options we'll take advantage of a feature in 'nopt'
# to stop option parsing, the '--'.
# NOTE: because the coffee command itself uses '--' to accept options for itself
#       it will eat it. so, we must type it twice, like: "-- --"

# allow debugging messages
debug = require('debug')('scram')

# use 'nopt' to parse options for scram and produce remaining for script
nopt = require 'nopt'

# use path to resolve paths to scripts
path = require 'path'

# use fs to check if file exists
fs = require 'fs'

# use child_process to run the script
{spawn} = require 'child_process'

# use process-messenger to handle the InterProcess Communication
ProcessMessenger = require 'process-messenger'

# specify scram options and aliases
options =
    main:
        status: Boolean     # show status during processing
        color:  Boolean     # show status in color, if status is enabled
        lib:    path        # path to script library, defaults to ./scripts
    alias:
        s:  [ "--status" ]
        c:  [ "--color" ]
        l:  [ "--lib" ]

# parse our options
config = nopt options.main, options.alias, process.argv, 2


# apply default values (there is an issue and pull request for defaults in nopt)
config.status ?= true
config.color  ?= true
config.lib    ?= path.resolve './scripts'

# print configs to debug
debug 'status: %s', config.status
debug 'color: %s', config.color
debug 'lib: %s', config.lib
debug 'remain: %s', config.argv?.remain

# get script's path and args
scriptArgs = config.argv?.remain?[1..]
debug 'scriptArgs: %s', scriptArgs

# use a namespace to contain local variables
scriptPath = do (lib = config.lib, name = config.argv?.remain?[0]) ->
    debug 'find: %s', name
    for ext in [ '', '.js', '.coffee', '.litcoffee', '.coffee.md' ]
        file = if ext isnt '' then path.join name, ext else name
        if fs.existsSync file then return file
        # else try combining with 'lib'
        scriptPath = path.resolve lib, file
        if fs.existsSync scriptPath then return scriptPath

    # not found as-is, not found with added extension, or paired with lib.
    # where else do we look?!
    console.error 'Unable to find script for: ' + name
    process.exit 1

debug 'scriptPath: %s', scriptPath

# determine whether to use node or coffee to execute script
exe = switch
    when /\.js$/i.test scriptPath then 'node'
    # this could match: .litcoffee.md  I don't mind.
    when /\.(lit)?coffee(\.md)?/i.test scriptPath then 'coffee'
    else 'coffee'

debug 'exe: %s', exe

# combine scriptPath into the args array for spawn
scriptArgs.unshift scriptPath

# spawn the script in a child process
script = spawn exe, scriptArgs,
    # share the environment settings
    env: process.env
    # share the stdio streams, and create an inter-process communication stream
    stdio: [ process.stdin, process.stdout, process.stderr, 'ipc' ]

# listen for messages from the script
script.on 'message', (msg) ->
    switch msg.type
        when 'count' then console.log 'count : ' + msg.count

# listen for errors in the script
script.on 'error', (error) ->
    console.error 'error in script: ' + error.message
    # TODO: do we do script.kill() or is already done?

# listen for the script to close
script.on 'close', (exitCode) ->
    debug 'exit code: %s', exitCode
    console.log 'Done.'

debug 'called script runner...'

