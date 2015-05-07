
describe "environment", ->
    it "should have window", -> expect(window).to.be.ok
    it "should have global", -> expect(global).to.be.ok
    it "should have env", -> expect(global.ENV).to.be.ok
