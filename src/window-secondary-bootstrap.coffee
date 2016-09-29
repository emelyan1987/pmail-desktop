# Swap out Node's native Promise for Bluebird, which allows us to
# do fancy things like handle exceptions inside promise blocks
global.Promise = require 'bluebird'
Promise.setScheduler(global.setImmediate)

# Like sands through the hourglass, so are the days of our lives.
require './window'

# Skip "?loadSettings=".
# loadSettings = JSON.parse(decodeURIComponent(location.search.substr(14)))
# {windowType} = loadSettings

PlanckEnvConstructor = require './planck-env'
window.PlanckEnv = window.atom = PlanckEnvConstructor.loadOrCreate()
global.Promise.longStackTraces() if PlanckEnv.inDevMode()
PlanckEnv.initialize()
PlanckEnv.startSecondaryWindow()

# Workaround for focus getting cleared upon window creation
windowFocused = ->
  window.removeEventListener('focus', windowFocused)
  setTimeout (-> document.querySelector('body').focus()), 0
window.addEventListener('focus', windowFocused)
