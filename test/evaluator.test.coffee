
p = require "../src/parser"
e = require "../src/evaluator"

describe "evaluator", ->
    it "should accept literal number", ->
        expect(e p "1").to.equal 1
    it "should accept literal string", ->
        expect(e p "'1'").to.equal "1"
    it "should accept single unary", ->
        expect(e p "!1").to.equal false
    it "should accept double unary", ->
        expect(e p "!!1").to.equal true
    it "should accept binary", ->
        expect(e p "1+1").to.equal 2
    it "should respect oop", ->
        expect(e p "1 + 2 * 3").to.equal 7
    it "should respect groups", ->
        expect(e p "(1 + 2) * 3").to.equal 9
    it "should accept empty array", ->
        expect((e p "[]").toString()).to.equal [ ].toString()
    it "should accept array of one", ->
        expect((e p "[1]").toString()).to.equal [1].toString()
    it "should accept array of many", ->
        expect((e p "[1, 2,3]").toString()).to.equal [1, 2, 3].toString()
    it "should accept identifier", ->
        expect(e p "$undef").to.equal undefined
    it "should return identifier evaluation", ->
        expect(e p "$id = 4").to.equal 4
    it "should return identifier should remember", ->
        expect(e p "$id").to.equal 4
    it "should accept bound identifiers in equations", ->
        expect(e p "$id * 4").to.equal 16
    it "should accept identifier bindings from equations", ->
        expect(e p "$id = 5 % 3").to.equal 2
    it "should accept identifier bindings using identifiers", ->
        expect(e p "$id = $id * 3").to.equal 6
