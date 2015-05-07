
window?.global = window
global?.window = global

global.ENV_NODE = "node"
global.ENV_BROWSER = "browser"

if process?
    global.chai = require "chai"
    global.ENV = global.ENV_NODE
else
    global.ENV = global.ENV_BROWSER

global.expect = chai.expect
global.assert = chai.assert
