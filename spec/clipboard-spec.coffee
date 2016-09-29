describe "Clipboard", ->
  describe "write(text, metadata) and read()", ->
    it "writes and reads text to/from the native clipboard", ->
      expect(PlanckEnv.clipboard.read()).toBe 'initial clipboard content'
      PlanckEnv.clipboard.write('next')
      expect(PlanckEnv.clipboard.read()).toBe 'next'

    it "returns metadata if the item on the native clipboard matches the last written item", ->
      PlanckEnv.clipboard.write('next', {meta: 'data'})
      expect(PlanckEnv.clipboard.read()).toBe 'next'
      expect(PlanckEnv.clipboard.readWithMetadata().text).toBe 'next'
      expect(PlanckEnv.clipboard.readWithMetadata().metadata).toEqual {meta: 'data'}
