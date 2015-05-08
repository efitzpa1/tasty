
parser = require "../src/parser"

describe "parser", ->
    describe "arguments", ->
        it "takes one string", -> expect ->
            parser "1 + 1"
        .to.not.throw Error
        it "takes empty string", -> expect ->
            parser ""
        .to.not.throw Error
        it "doesnt take other types", -> expect ->
            parser 1
        .to.throw Error

    describe "running cases", ->
        describe "binary operators", ->
            it "reject with no rhs", -> expect ->
                parser "1 + "
            .to.throw Error
            it "reject with no lhs", -> expect ->
                parser " % 2"
            .to.throw Error
            it "reject with no lhs and no rhs", -> expect ->
                parser ">"
            .to.throw Error
            it "accept with both sides", -> expect ->
                parser "1 - 2"
            .to.not.throw Error

        describe "unary operators", ->
            it "reject with no rhs", -> expect ->
                parser "!"
            .to.throw Error
            it "accept with a rhs", -> expect ->
                parser "!4"
            .to.not.throw Error
            it "accept nests", -> expect ->
                parser "!!4"
            .to.throw Error

        describe "literals", ->
            it "reject mismatched quotes", -> expect ->
                parser "\"\'"
            .to.throw Error
            it "accept empty strings", -> expect ->
                parser "\"\""
            .to.not.throw Error
            it "accept non-empty strings", -> expect ->
                parser "\"test\""
            .to.not.throw Error
            it "accept a number", -> expect ->
                parser "1"
            .to.not.throw Error
            it "accept scientific number", -> expect ->
                parser "2e4"
            .to.not.throw Error
            it "accpet floating number", -> expect ->
                parser "1.2"
            .to.not.throw Error

        describe "identifiers", ->
            it "reject starting with numbers", -> expect ->
                parser "4h"
            .to.throw.Error
            it "accept standard variable names", -> expect ->
                parser "$var"
                parser "_test"
                parser "absolutely_the_best_variable_of_all_time"
            .to.not.throw Error

        describe "arrays", ->
            it "reject unclosed arrays", -> expect ->
                parser "[4, 2, lol, k"
            .to.throw.Error
            it "reject mismatched terminators", -> expect ->
                parser "[2 + 3 * 9)"
            .to.throw.Error
            it "reject consecutive commas", -> expect ->
                parser "[2,3,4,5,,]"
            .to.throw.Error
            it "accept properly closed arrays", -> expect ->
                parser "[2 + 3 * 4 + 1]"
            .to.not.throw Error
            it "accept arrays within arrays", -> expect ->
                parser "[2, [3 - 2 * 6], 4]"
            .to.not.throw Error
            it "accept empty arrays", -> expect ->
                parser "[]"
            .to.not.throw Error

        describe "groups", ->
            it "reject unclosed group", -> expect ->
                parser "(2 - 3 + 4"
            .to.throw.Error
            it "reject mismatched terminators", -> expect ->
                parser "(2 + 3 - 4]"
            .to.throw.Error
            it "reject non binary or unary expressions", -> expect ->
                parser "(2 + 3, 6)"
            .to.throw.Error
            it "reject empty groups", -> expect ->
                parser "()"
            .to.throw Error
            it "accept properly closed groups", -> expect ->
                parser "(2 + 3 - 4 / 5)"
            .to.not.throw Error

        describe "members", ->
            it "reject consecutive periods", -> expect ->
                parser "a..b"
            .to.throw Error
            it "accept member access", -> expect ->
                parser "a.b"
            .to.not.throw Error
            it "accept multiple member access", -> expect ->
                parser "a.b.c.d"
            .to.not.throw Error
