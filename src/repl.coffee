
e = require "./evaluator"
p = require "./parser"

repl = require "repl"

repl.start
    prompt: "> "
    eval: ( cmd, context, filename, callback) ->
        cmd = cmd.match(/\((.*)/)[1]
        try
            result = p cmd
            console.log result
            result = e result
        catch error
            result = error
        callback null, result
    input: process.stdin
    output: process.stdout
