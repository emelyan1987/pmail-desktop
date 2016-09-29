module.exports =
  activateCallCount: 0
  activationCommandCallCount: 0
  legacyActivationCommandCallCount: 0

  activate: ->
    @activateCallCount++

    PlanckEnv.commands.add 'nylas-workspace', 'activation-command', =>
      @activationCommandCallCount++

    editorView = PlanckEnv.views.getView(PlanckEnv.workspace.getActiveTextEditor())?.__spacePenView
    editorView?.command 'activation-command', =>
      @legacyActivationCommandCallCount++
