
e = require "./evaluator"
p = require "./parser"

repl = require "repl"

repl.start
    prompt: "> "
    eval: ( cmd, context, filename, callback) ->
        cmd = cmd.match(/\((.*)/)[1]
        try
            result = e p cmd
        catch error
            result = error
        callback null, result
    input: process.stdin
    output: process.stdout
