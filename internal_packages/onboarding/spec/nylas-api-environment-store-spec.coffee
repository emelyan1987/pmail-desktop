Actions = require '../lib/onboarding-actions'
NylasApiEnvironmentStore = require '../lib/nylas-api-environment-store'
storeConstructor = NylasApiEnvironmentStore.constructor

describe "NylasApiEnvironmentStore", ->
  beforeEach ->
    spyOn(PlanckEnv.config, "set")

  it "doesn't set if it alreayd exists", ->
    spyOn(PlanckEnv.config, "get").andReturn "staging"
    store = new storeConstructor()
    expect(PlanckEnv.config.set).not.toHaveBeenCalled()

  it "initializes with the correct default in dev mode", ->
    spyOn(PlanckEnv, "inDevMode").andReturn true
    spyOn(PlanckEnv.config, "get").andReturn undefined
    store = new storeConstructor()
    expect(PlanckEnv.config.set).toHaveBeenCalledWith("env", "production")

  it "initializes with the correct default in production", ->
    spyOn(PlanckEnv, "inDevMode").andReturn false
    spyOn(PlanckEnv.config, "get").andReturn undefined
    store = new storeConstructor()
    expect(PlanckEnv.config.set).toHaveBeenCalledWith("env", "production")

  describe "when setting the environment", ->
    it "sets from the desired action", ->
      Actions.changeAPIEnvironment("staging")
      expect(PlanckEnv.config.set).toHaveBeenCalledWith("env", "staging")

    it "throws if the env is invalid", ->
      expect( -> Actions.changeAPIEnvironment("bad")).toThrow()

    it "throws if the env is blank", ->
      expect( -> Actions.changeAPIEnvironment()).toThrow()
