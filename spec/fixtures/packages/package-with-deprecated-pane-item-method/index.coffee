class TestItem
  getUri: -> "test"

exports.activate = ->
  PlanckEnv.workspace.addOpener -> new TestItem
