
# chunk statemachine inspired by jsep
# operator precedence from
# https://developer.mozilla.org/en-US/docs/Web/JavaScript/
#     Reference/Operators/Operator_Precedence
# regex from various stack overflow blogs
#
# @author Christopher Kelley
# @author Eric Fitzpatrick

ASCII = { }
for a in [0...128] by 1
    ASCII[String.fromCharCode a] = a

module.exports = __module__ =
# This class' main functionality is to take a string and return
# an object with type, operator, left hand side, and right hand side.
#
# @example How to parse an expression.
#   Parser.parse("1 + 2")
#
# @class Parser
class Parser

    # Returns the longest key in the provided object.
    #
    # @memberof Parser
    # @private
    # @param [Object] obj given object
    # @return [Number] max longest key length
    max_key_length = ( obj ) ->
        max = 0
        for own key of obj
            max = key.length if key.length > max
        return max

    # Returns an error object and prints an error message based on input.
    #
    # @memberof Parser
    # @private
    # @param [String] msg error message you want to print
    # @param [Number] index line of error message occurance
    # @return [Object] err object that was created
    error = ( msg, index ) ->
        err = new Error "tasty: at #{index}: #{msg}"
        err.index = index
        err.description = msg
        return err

    # coffeelint: disable=colon_assignment_spacing
    # reason: code readability via alignment

    # Unary object containing known unary operators and their precedence.
    # @private
    UNARY =
        "-"     : 15
        "!"     : 15
        "~"     : 15
        "+"     : 15

    # Binary object containing known binary operators and their precedence.
    # @memberof Parser
    # @private
    BINARY =
        # symbol: precedence
        "="     : 3
        "||"    : 5
        "&&"    : 6
        "|"     : 7
        "^"     : 8
        "&"     : 9
        "=="    : 10
        "!="    : 10
        "==="   : 10
        "!=="   : 10
        "<"     : 11
        ">"     : 11
        "<="    : 11
        ">="    : 11
        "<<"    : 12
        ">>"    : 12
        ">>>"   : 12
        "+"     : 13
        "-"     : 13
        "*"     : 14
        "/"     : 14
        "%"     : 14

    MAX_UNARY = max_key_length UNARY
    MAX_BINARY = max_key_length BINARY

    # Literal object to convert strings to values.
    # @memberof Parser
    # @private
    LITERAL =
        "true"  : true
        "false" : false
        "null"  : null
        "undefined": undefined

    # coffeelint: enable=colon_assignment_spacing

    # @memberof Parser
    _start =
        decimal: ( c ) ->
            c in [ ASCII["+"], ASCII["-"], ASCII["."] ] or
                ASCII["0"] <= c <= ASCII["9"]
        string: ( c ) ->
            c in [ ASCII["\""], ASCII["\'"] ]
        identifier: ( c ) ->
            c in [ ASCII["$"], ASCII["_"] ] or
                ASCII["A"] <= c <= ASCII["Z"] or
                ASCII["a"] <= c <= ASCII["z"]

    # specifies type of current operator or symbol
    #
    # @memberof Parser
    # @static
    # @private
    @TYPE_BINARY     = 0

    # specifies type of current operator or symbol
    #
    # @memberof Parser
    # @static
    # @private
    @TYPE_UNARY      = 1

    # specifies type of current operator or symbol
    #
    # @memberof Parser
    # @static
    # @private
    @TYPE_LITERAL    = 2

    # specifies type of current operator or symbol
    #
    # @memberof Parser
    # @static
    # @private
    @TYPE_IDENTIFIER = 3

    # specifies type of current operator or symbol
    #
    # @memberof Parser
    # @static
    # @private
    @TYPE_CONTEXT    = 4

    # specifies type of current operator or symbol
    #
    # @memberof Parser
    # @static
    # @private
    @TYPE_ARRAY      = 5

    # specifies type of current operator or symbol
    #
    # @memberof Parser
    # @static
    # @private
    @TYPE_CALL       = 6

    # specifies type of current operator or symbol
    #
    # @memberof Parser
    # @static
    # @private
    @TYPE_MEMBER     = 7

    # specifies type of current operator or symbol
    #
    # @memberof Parser
    # @static
    # @private
    @TYPE_COMPOUND   = 8

    # Constructors for expression objects.
    #
    # @memberof Parser
    # @private
    _make =
        # constructor for binary object
        #
        # @memberof Parser
        # @private
        # @param [String] op binary operator
        # @param [Object] lhs left hand side of binary operation
        # @param [Object] rhs right hand side of binary operation
        binary: ( op, lhs, rhs ) ->
            type: Parser.TYPE_BINARY
            op: op
            lhs: lhs
            rhs: rhs
        # constructor for unary object
        #
        # @memberof Parser
        # @private
        # @param [String] op unary operator
        # @param [Object] rhs right hand side of unary operation
        unary: ( op, rhs ) ->
            type: Parser.TYPE_UNARY
            op: op
            rhs: rhs
            lhs: null
        # constructor for literal object
        #
        # @memberof Parser
        # @private
        # @param [String] literal value
        literal: ( value ) ->
            type: Parser.TYPE_LITERAL
            val: value
        # constructor for identifier object
        #
        # @memberof Parser
        # @private
        # @param [String] value identifier name
        identifier: ( value ) ->
            type: Parser.TYPE_IDENTIFIER
            val: value
        # constructor for context object
        #
        # @memberof Parser
        # @private
        context: ( ) ->
            type: Parser.TYPE_CONTEXT
        # constructor for array object
        #
        # @memberof Parser
        # @private
        # @param [Array] value array object to wrap
        array: ( value ) ->
            type: Parser.TYPE_ARRAY
            val: value
        # constructor for member object
        #
        # @memberof Parser
        # @private
        # @param [String] value member name to wrap
        # @param [Object] callee context calling this member
        # @param [Boolean] computed if value is accessed with dot or compute
        member: ( value, callee, computed ) ->
            type: Parser.TYPE_MEMBER
            val: value
            callee: callee
            computed: computed
        # constructor for call object
        #
        # @memberof Parser
        # @private
        # @param
        # @param
        call: ( callee, args ) ->
            type: Parser.TYPE_CALL
            callee: callee
            args: args


    # Parses the given expression.
    # @memberof Parser
    # @function parse
    # @param [String] expr the expression you want to parse
    # @return { type, operator, lhs, rhs }
    # @static
    constructor: ( expr ) ->

        index = 0

        if "string" isnt typeof expr
            throw new TypeError "tasty: invalid argument, expected string,
            got #{typeof expr}
            "

        icode = expr.charCodeAt.bind expr

        consume =
            # Moves the index to the first non-space/tab character.
            spaces: ( ) ->
                c = icode index
                while c in [ ASCII["\t"], ASCII[" "] ] # tab, space
                    c = icode ++index
                return false

            binary:
                # Tries to return the binary operator at the current index.
                #
                # @return [String] lookat the binary operator
                op: ( ) ->
                    consume.spaces()
                    # start from the longest string and work to nothing
                    # if match exists in expressions return it and move index
                    lookat = expr.substr index, MAX_BINARY
                    while lookat.length
                        if BINARY[lookat]
                            index += lookat.length
                            return lookat
                        lookat = lookat.substr 0, lookat.length - 1

                    return false

                # Tries to return a binary expression object
                # at the current index.
                #
                # @return [Object] rhs the binary exp object
                expr: ( ) ->
                    consume.spaces()

                    # obtain the left token
                    lhs = consume.token()

                    biop = consume.binary.op()

                    # maybe guessed wrong, return just lhs
                    # lets me be lazy (good lazy) in outer while loop
                    return lhs unless biop

                    # obtain the right token
                    rhs = consume.token()

                    throw error "expected token", index unless rhs

                    # start an infix stack
                    stack = [ lhs, biop, rhs ]

                    # continue looking for operators
                    while biop = consume.binary.op()
                        break unless prec = BINARY[biop]

                        # figure out where in the stack the operator should go
                        # compress stack forward
                        while stack.length > 2 and
                        prec <= BINARY[stack[stack.length - 2]]
                            rhs = stack.pop()
                            stack.push _make.binary stack.pop(),
                                stack.pop(), rhs

                        rhs = consume.token()
                        throw error "expected token", index unless rhs

                        stack.push biop, rhs

                    # compress stack backward
                    rhs = stack[stack.length - 1]
                    for i in [stack.length - 1..1] by -2
                        rhs = _make.binary stack[i - 1], stack[i - 2], rhs

                    return rhs

            unary:
                # Tries to return the unary operator at the current index.
                #
                # @return [String] lookat the unary operator
                op: ( ) ->
                    consume.spaces()
                    # start from the longest string and work to nothing
                    # if match exists in expressions return it and move index
                    lookat = expr.substr index, MAX_UNARY
                    while lookat.length
                        if UNARY[lookat]
                            index += lookat.length
                            return lookat
                        lookat = lookat.substr 0, lookat.length - 1

                    return false

                # Tries to return the unary expression object
                # at the current index.
                expr: ( ) ->
                    consume.spaces()

                    unop = consume.unary.op()

                    throw error "expected token", index unless unop

                    _make.unary unop, consume.token()


            literal:
                # Returns the literal object of the number at the current index.
                #
                # @return [Object] literal object
                number: ( ) ->
                    consume.spaces()

                    number = expr.substr index
                        .match(/[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?/)[0]
                    index += number.length
                    return _make.literal Number(number)

                # Returns the literal object of the string at the current index.
                #
                # @return [Object] literal object
                string: ( ) ->
                    consume.spaces()

                    # store first quote and move forward
                    pls = expr.substr index
                        .match /["]((?:[^\\"]|\\.)*)["]|[']((?:[^\\']|\\.)*)[']/
                    throw error "unclosed string", index unless pls?

                    if pls[1]?
                        pls = pls[1]
                    else if pls[2]?
                        pls = pls[2]

                    throw error "unclosed string", index unless pls?

                    index += pls.length + 2 # to account quotes

                    pls = pls
                        .replace("\\r", "\r")
                        .replace("\\n", "\n")
                        .replace("\\t", "\t")
                        .replace("\\b", "\b")
                        .replace("\\f", "\f")
                        .replace("\\\"", "\"")
                        .replace("\\\\", "\\")
                        .replace("\\\'", "\'")
                    # its a little gross - should come up with something better

                    return _make.literal pls

            # Either returns a literal or identifier object
            # based on what is at the current index.
            #
            # @return [Object] literal/identifier object
            identifier: ( ) ->
                consume.spaces()

                id = expr.substr(index).match(/^[$A-Za-z_][$0-9a-z_]*/)

                throw error "invalid identifier", index unless id
                id = id[0]
                index += id.length

                # identifier may be this type, literal or actual identifier
                switch
                    when LITERAL[id] then _make.literal LITERAL[id]
                    when "this" is id then _make.context()
                    else _make.identifier id

            # Returns an array of all that is inside the list at
            # the current index.
            #
            # @return [Object] array
            list: ( ) ->
                termination = switch icode index++
                    when ASCII["("] then ASCII[")"]
                    when ASCII["["] then ASCII["]"]
                    else throw error "invalid list", index

                array = [ ]

                while index < expr.length
                    consume.spaces()
                    c = icode index
                    if c is termination
                        index++
                        break
                    else if c is ASCII[","]
                        index++
                    else
                        unless node = consume.binary.expr()
                            throw error "unexpected comma", index
                        array.push node

                return array

            group: ( ) ->
                # move after opening paren
                index += 1
                # get generic expression within group
                e = consume.binary.expr()
                # remove trailing spaces (     5+5     )
                consume.spaces()
                # die if not properly closed
                if ASCII[")"] isnt icode index++
                    throw error "unclosed group", index - 1

                return e

            # Makes an array.
            array: ( ) ->
                _make.array consume.list()

            # in actuality we only have tokens
            # binary expressions are special and handled externally
            # esentially token is all but binary expressions
            #
            # @return [Object]
            token: ( ) ->
                consume.spaces()

                c = icode index # NO INCR
                switch
                    when _start.decimal c
                        consume.literal.number()
                    when _start.string c
                        consume.literal.string()
                    when _start.identifier(c) or c is ASCII["("]
                        consume.object()
                    when c is ASCII["["]
                        consume.array()
                    else
                        consume.unary.expr()

            # object is like a continuation of token
            # which looks for members and calls
            object: ( ) ->
                c = icode index

                if c is ASCII["("]
                    node = consume.group()
                else # assert from token this must be identifier
                    node = consume.identifier()

                consume.spaces()

                # dear coffee, why you no have do-while

                c = icode index # index changed by consumes

                while c in [ ASCII["."], ASCII["["], ASCII["("] ]
                    switch c
                        when ASCII["."] # member
                            index += 1
                            #c = icode index
                            #if c is ASCII["."]
                            #    throw error "unexpected member access", index
                            node = _make.member consume.identifier(),
                                node, false
                        when ASCII["["] # computed member (not array!)
                            index += 1
                            node = _make.member consume.binary.expr(),
                                node, true
                            # check for closing
                            unless icode(index++) is ASCII["]"]
                                throw error "unclosed computed member", index
                        when ASCII["("] # function
                            node = _make.call node, consume.list()
                    consume.spaces()
                    c = icode index


                return node

        nodes = [ ]
        while index < expr.length
            c = icode index
            # semicolon and comma insertion, ignore
            if c in [ ASCII[";"], ASCII[","] ]
                index++
            else
                unless node = consume.binary.expr()
                    throw error "unexpected expression", index
                nodes.push node

        if 1 is nodes.length
            return nodes[0]

        type: Parser.COMPOUND
        val: nodes
