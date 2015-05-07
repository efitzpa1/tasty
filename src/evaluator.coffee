
parser = require "./parser"

context = { }
last_id = null

module.exports = __module__ =

class Evaluator

    # coffeelint: disable=colon_assignment_spacing
    # reason: code readability via alignment

    # coffeelint: disable=no_backticks
    # reason: needed for unstrict evaluation

    BINARY =
        "="  : ( lhs, rhs ) -> context[last_id] = rhs
        "||" : ( lhs, rhs ) -> lhs or rhs
        "&&" : ( lhs, rhs ) -> lhs and rhs
        "|"  : ( lhs, rhs ) -> lhs | rhs
        "^"  : ( lhs, rhs ) -> lhs ^ rhs
        "&"  : ( lhs, rhs ) -> lhs & rhs
        "==" : ( lhs, rhs ) -> `lhs == rhs`
        "!=" : ( lhs, rhs ) -> `lhs != rhs`
        "===": ( lhs, rhs ) -> lhs is rhs
        "!==": ( lhs, rhs ) -> lhs isnt rhs
        "<"  : ( lhs, rhs ) -> lhs < rhs
        ">"  : ( lhs, rhs ) -> lhs > rhs
        "<=" : ( lhs, rhs ) -> lhs <= rhs
        ">=" : ( lhs, rhs ) -> lhs >= rhs
        "<<" : ( lhs, rhs ) -> lhs << rhs
        ">>" : ( lhs, rhs ) -> lhs >> rhs
        ">>>": ( lhs, rhs ) -> lhs >>> rhs
        "+"  : ( lhs, rhs ) -> lhs + rhs
        "-"  : ( lhs, rhs ) -> lhs - rhs
        "*"  : ( lhs, rhs ) -> lhs * rhs
        "/"  : ( lhs, rhs ) -> lhs / rhs
        "%"  : ( lhs, rhs ) -> lhs % rhs

    UNARY =
        "-": ( rhs ) -> -rhs
        "!": ( rhs ) -> not rhs
        "~": ( rhs ) -> ~rhs
        "+": ( rhs ) -> +rhs

    # coffeelint: enable=colon_assignment_spacing
    # coffeelint: enable=no_backticks

    constructor: ( ast ) ->

        switch ast.type
            when parser.TYPE_BINARY
                if not BINARY[ast.op]
                    throw new Error "tasty: unknown binary operator #{ast.op}"
                return BINARY[ast.op] (__module__ ast.lhs), (__module__ ast.rhs)
            when parser.TYPE_UNARY
                if not UNARY[ast.op]
                    throw new Error "tasty: unknown unary operator #{ast.op}"
                return UNARY[ast.op] (__module__ ast.rhs)
            when parser.TYPE_LITERAL
                return ast.val
            when parser.TYPE_IDENTIFIER
                last_id = ast.val
                return context[ast.val]
            when parser.TYPE_ARRAY
                return ast.val.map ( ast ) -> __module__ ast
            else
                (console.log ast) or 0

try
    if process
        fs = require "fs"
        process.on "exit", ->
            fs.writeFileSync ".evalctx", JSON.stringify context
        context = JSON.parse fs.readFileSync ".evalctx"
catch ignored
    undefined
