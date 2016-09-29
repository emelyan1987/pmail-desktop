path = require 'path'
{$, $$} = require '../src/space-pen-extensions'
Package = require '../src/package'
DatabaseStore = require '../src/flux/stores/database-store'
{Disposable} = require 'event-kit'

describe "PackageManager", ->
  workspaceElement = null

  beforeEach ->
    workspaceElement = document.createElement('nylas-workspace')
    jasmine.attachToDOM(workspaceElement)

  describe "::loadPackage(name)", ->
    beforeEach ->
      PlanckEnv.config.set("core.disabledPackages", [])

    it "returns the package", ->
      pack = PlanckEnv.packages.loadPackage("package-with-index")
      expect(pack instanceof Package).toBe true
      expect(pack.metadata.name).toBe "package-with-index"

    it "returns the package if it has an invalid keymap", ->
      spyOn(console, 'warn')
      spyOn(console, 'error')
      pack = PlanckEnv.packages.loadPackage("package-with-broken-keymap")
      expect(pack instanceof Package).toBe true
      expect(pack.metadata.name).toBe "package-with-broken-keymap"

    it "returns the package if it has an invalid stylesheet", ->
      spyOn(console, 'warn')
      spyOn(console, 'error')
      pack = PlanckEnv.packages.loadPackage("package-with-invalid-styles")
      expect(pack instanceof Package).toBe true
      expect(pack.metadata.name).toBe "package-with-invalid-styles"
      expect(pack.stylesheets.length).toBe 0

    it "returns null if the package has an invalid package.json", ->
      spyOn(console, 'warn')
      spyOn(console, 'error')
      expect(PlanckEnv.packages.loadPackage("package-with-broken-package-json")).toBeNull()
      expect(console.warn.callCount).toBe(2)
      expect(console.warn.argsForCall[0][0]).toContain("Failed to load package.json")

    it "returns null if the package is not found in any package directory", ->
      spyOn(console, 'warn')
      spyOn(console, 'error')
      expect(PlanckEnv.packages.loadPackage("this-package-cannot-be-found")).toBeNull()
      expect(console.warn.callCount).toBe(1)
      expect(console.warn.argsForCall[0][0]).toContain("Could not resolve")

    it "invokes ::onDidLoadPackage listeners with the loaded package", ->
      loadedPackage = null
      PlanckEnv.packages.onDidLoadPackage (pack) -> loadedPackage = pack

      PlanckEnv.packages.loadPackage("package-with-main")

      expect(loadedPackage.name).toBe "package-with-main"

  describe "::unloadPackage(name)", ->
    describe "when the package is active", ->
      it "throws an error", ->
        pack = null
        waitsForPromise ->
          PlanckEnv.packages.activatePackage('package-with-main').then (p) -> pack = p

        runs ->
          expect(PlanckEnv.packages.isPackageLoaded(pack.name)).toBeTruthy()
          expect(PlanckEnv.packages.isPackageActive(pack.name)).toBeTruthy()
          expect( -> PlanckEnv.packages.unloadPackage(pack.name)).toThrow()
          expect(PlanckEnv.packages.isPackageLoaded(pack.name)).toBeTruthy()
          expect(PlanckEnv.packages.isPackageActive(pack.name)).toBeTruthy()

    describe "when the package is not loaded", ->
      it "throws an error", ->
        expect(PlanckEnv.packages.isPackageLoaded('unloaded')).toBeFalsy()
        expect( -> PlanckEnv.packages.unloadPackage('unloaded')).toThrow()
        expect(PlanckEnv.packages.isPackageLoaded('unloaded')).toBeFalsy()

    describe "when the package is loaded", ->
      it "no longers reports it as being loaded", ->
        pack = PlanckEnv.packages.loadPackage('package-with-main')
        expect(PlanckEnv.packages.isPackageLoaded(pack.name)).toBeTruthy()
        PlanckEnv.packages.unloadPackage(pack.name)
        expect(PlanckEnv.packages.isPackageLoaded(pack.name)).toBeFalsy()

    it "invokes ::onDidUnloadPackage listeners with the unloaded package", ->
      PlanckEnv.packages.loadPackage('package-with-main')
      unloadedPackage = null
      PlanckEnv.packages.onDidUnloadPackage (pack) -> unloadedPackage = pack
      PlanckEnv.packages.unloadPackage('package-with-main')
      expect(unloadedPackage.name).toBe 'package-with-main'

  describe "::activatePackage(id)", ->
    describe "when called multiple times", ->
      it "it only calls activate on the package once", ->
        spyOn(Package.prototype, 'activateNow').andCallThrough()
        waitsForPromise ->
          PlanckEnv.packages.activatePackage('package-with-index')
        waitsForPromise ->
          PlanckEnv.packages.activatePackage('package-with-index')
        waitsForPromise ->
          PlanckEnv.packages.activatePackage('package-with-index')

        runs ->
          expect(Package.prototype.activateNow.callCount).toBe 1

    describe "when the package has a main module", ->
      describe "when the metadata specifies a main module path˜", ->
        it "requires the module at the specified path", ->
          mainModule = require('./fixtures/packages/package-with-main/main-module')
          spyOn(mainModule, 'activate')
          pack = null
          waitsForPromise ->
            PlanckEnv.packages.activatePackage('package-with-main').then (p) -> pack = p

          runs ->
            expect(mainModule.activate).toHaveBeenCalled()
            expect(pack.mainModule).toBe mainModule

      describe "when the metadata does not specify a main module", ->
        it "requires index.coffee", ->
          indexModule = require('./fixtures/packages/package-with-index/index')
          spyOn(indexModule, 'activate')
          pack = null
          waitsForPromise ->
            PlanckEnv.packages.activatePackage('package-with-index').then (p) -> pack = p

          runs ->
            expect(indexModule.activate).toHaveBeenCalled()
            expect(pack.mainModule).toBe indexModule

      it "assigns config schema, including defaults when package contains a schema", ->
        expect(PlanckEnv.config.get('package-with-config-schema.numbers.one')).toBeUndefined()

        waitsForPromise ->
          PlanckEnv.packages.activatePackage('package-with-config-schema')

        runs ->
          expect(PlanckEnv.config.get('package-with-config-schema.numbers.one')).toBe 1
          expect(PlanckEnv.config.get('package-with-config-schema.numbers.two')).toBe 2

          expect(PlanckEnv.config.set('package-with-config-schema.numbers.one', 'nope')).toBe false
          expect(PlanckEnv.config.set('package-with-config-schema.numbers.one', '10')).toBe true
          expect(PlanckEnv.config.get('package-with-config-schema.numbers.one')).toBe 10

      describe "when a package has configDefaults", ->
        beforeEach ->
          jasmine.snapshotDeprecations()

        afterEach ->
          jasmine.restoreDeprecationsSnapshot()

        # it "still assigns configDefaults from the module though deprecated", ->
        #
        #   expect(PlanckEnv.config.get('package-with-config-defaults.numbers.one')).toBeUndefined()
        #
        #   waitsForPromise ->
        #     PlanckEnv.packages.activatePackage('package-with-config-defaults')
        #
        #   runs ->
        #     expect(PlanckEnv.config.get('package-with-config-defaults.numbers.one')).toBe 1
        #     expect(PlanckEnv.config.get('package-with-config-defaults.numbers.two')).toBe 2

    describe "when the package has no main module", ->
      it "does not throw an exception", ->
        spyOn(console, "error")
        spyOn(console, "warn")
        expect(-> PlanckEnv.packages.activatePackage('package-without-module')).not.toThrow()
        expect(console.error).not.toHaveBeenCalled()
        expect(console.warn).not.toHaveBeenCalled()

    it "passes the activate method the package's previously serialized state if it exists", ->
      pack = null
      waitsForPromise ->
        PlanckEnv.packages.activatePackage("package-with-serialization").then (p) -> pack = p

      runs ->
        expect(pack.mainModule.someNumber).not.toBe 77
        pack.mainModule.someNumber = 77
        PlanckEnv.packages.deactivatePackage("package-with-serialization")
        spyOn(pack.mainModule, 'activate').andCallThrough()
        waitsForPromise ->
          PlanckEnv.packages.activatePackage("package-with-serialization")
        runs ->
          expect(pack.mainModule.activate.calls[0].args[0]).toEqual({someNumber: 77})

    it "invokes ::onDidActivatePackage listeners with the activated package", ->
      activatedPackage = null
      PlanckEnv.packages.onDidActivatePackage (pack) ->
        activatedPackage = pack

      PlanckEnv.packages.activatePackage('package-with-main')

      waitsFor -> activatedPackage?
      runs -> expect(activatedPackage.name).toBe 'package-with-main'

    describe "when the package throws an error while loading", ->
      it "logs a warning instead of throwing an exception", ->
        PlanckEnv.config.set("core.disabledPackages", [])
        spyOn(console, "log")
        spyOn(console, "warn")
        spyOn(console, "error")
        expect(-> PlanckEnv.packages.activatePackage("package-that-throws-an-exception")).not.toThrow()
        expect(console.warn).toHaveBeenCalled()

    describe "when the package is not found", ->
      it "rejects the promise", ->
        PlanckEnv.config.set("core.disabledPackages", [])

        onSuccess = jasmine.createSpy('onSuccess')
        onFailure = jasmine.createSpy('onFailure')
        spyOn(console, 'warn')
        spyOn(console, "error")

        PlanckEnv.packages.activatePackage("this-doesnt-exist").then(onSuccess, onFailure)

        waitsFor "promise to be rejected", ->
          onFailure.callCount > 0

        runs ->
          expect(console.warn.callCount).toBe 1
          expect(onFailure.mostRecentCall.args[0] instanceof Error).toBe true
          expect(onFailure.mostRecentCall.args[0].message).toContain "Failed to load package 'this-doesnt-exist'"

    describe "keymap loading", ->
      describe "when the metadata does not contain a 'keymaps' manifest", ->
        it "loads all the .cson/.json files in the keymaps directory", ->
          element1 = $$ -> @div class: 'test-1'
          element2 = $$ -> @div class: 'test-2'
          element3 = $$ -> @div class: 'test-3'

          expect(PlanckEnv.keymaps.findKeyBindings(keystrokes:'ctrl-z', target:element1[0])).toHaveLength 0
          expect(PlanckEnv.keymaps.findKeyBindings(keystrokes:'ctrl-z', target:element2[0])).toHaveLength 0
          expect(PlanckEnv.keymaps.findKeyBindings(keystrokes:'ctrl-z', target:element3[0])).toHaveLength 0

          waitsForPromise ->
            PlanckEnv.packages.activatePackage("package-with-keymaps")

          runs ->
            expect(PlanckEnv.keymaps.findKeyBindings(keystrokes:'ctrl-z', target:element1[0])[0].command).toBe "test-1"
            expect(PlanckEnv.keymaps.findKeyBindings(keystrokes:'ctrl-z', target:element2[0])[0].command).toBe "test-2"
            expect(PlanckEnv.keymaps.findKeyBindings(keystrokes:'ctrl-z', target:element3[0])).toHaveLength 0

      describe "when the metadata contains a 'keymaps' manifest", ->
        it "loads only the keymaps specified by the manifest, in the specified order", ->
          element1 = $$ -> @div class: 'test-1'
          element3 = $$ -> @div class: 'test-3'

          expect(PlanckEnv.keymaps.findKeyBindings(keystrokes:'ctrl-z', target:element1[0])).toHaveLength 0

          waitsForPromise ->
            PlanckEnv.packages.activatePackage("package-with-keymaps-manifest")

          runs ->
            expect(PlanckEnv.keymaps.findKeyBindings(keystrokes:'ctrl-z', target:element1[0])[0].command).toBe 'keymap-1'
            expect(PlanckEnv.keymaps.findKeyBindings(keystrokes:'ctrl-n', target:element1[0])[0].command).toBe 'keymap-2'
            expect(PlanckEnv.keymaps.findKeyBindings(keystrokes:'ctrl-y', target:element3[0])).toHaveLength 0

      describe "when the keymap file is empty", ->
        it "does not throw an error on activation", ->
          waitsForPromise ->
            PlanckEnv.packages.activatePackage("package-with-empty-keymap")

          runs ->
            expect(PlanckEnv.packages.isPackageActive("package-with-empty-keymap")).toBe true

    describe "menu loading", ->
      beforeEach ->
        PlanckEnv.menu.template = []

      describe "when the metadata does not contain a 'menus' manifest", ->
        it "loads all the .cson/.json files in the menus directory", ->
          element = ($$ -> @div class: 'test-1')[0]

          waitsForPromise ->
            PlanckEnv.packages.activatePackage("package-with-menus")

          runs ->
            expect(PlanckEnv.menu.template.length).toBe 2
            expect(PlanckEnv.menu.template[0].label).toBe "Second to Last"
            expect(PlanckEnv.menu.template[1].label).toBe "Last"

      describe "when the metadata contains a 'menus' manifest", ->
        it "loads only the menus specified by the manifest, in the specified order", ->
          element = ($$ -> @div class: 'test-1')[0]

          waitsForPromise ->
            PlanckEnv.packages.activatePackage("package-with-menus-manifest")

          runs ->
            expect(PlanckEnv.menu.template[0].label).toBe "Second to Last"
            expect(PlanckEnv.menu.template[1].label).toBe "Last"

      describe "when the menu file is empty", ->
        it "does not throw an error on activation", ->
          waitsForPromise ->
            PlanckEnv.packages.activatePackage("package-with-empty-menu")

          runs ->
            expect(PlanckEnv.packages.isPackageActive("package-with-empty-menu")).toBe true

    describe "stylesheet loading", ->
      describe "when the metadata contains a 'styleSheets' manifest", ->
        it "loads style sheets from the styles directory as specified by the manifest", ->
          one = require.resolve("./fixtures/packages/package-with-style-sheets-manifest/styles/1.css")
          two = require.resolve("./fixtures/packages/package-with-style-sheets-manifest/styles/2.less")
          three = require.resolve("./fixtures/packages/package-with-style-sheets-manifest/styles/3.css")

          one = PlanckEnv.themes.stringToId(one)
          two = PlanckEnv.themes.stringToId(two)
          three = PlanckEnv.themes.stringToId(three)

          expect(PlanckEnv.themes.stylesheetElementForId(one)).toBeNull()
          expect(PlanckEnv.themes.stylesheetElementForId(two)).toBeNull()
          expect(PlanckEnv.themes.stylesheetElementForId(three)).toBeNull()

          waitsForPromise ->
            PlanckEnv.packages.activatePackage("package-with-style-sheets-manifest")

          runs ->
            expect(PlanckEnv.themes.stylesheetElementForId(one)).not.toBeNull()
            expect(PlanckEnv.themes.stylesheetElementForId(two)).not.toBeNull()
            expect(PlanckEnv.themes.stylesheetElementForId(three)).toBeNull()
            expect($('#jasmine-content').css('font-size')).toBe '1px'

      describe "when the metadata does not contain a 'styleSheets' manifest", ->
        it "loads all style sheets from the styles directory", ->
          one = require.resolve("./fixtures/packages/package-with-styles/styles/1.css")
          two = require.resolve("./fixtures/packages/package-with-styles/styles/2.less")
          three = require.resolve("./fixtures/packages/package-with-styles/styles/3.test-context.css")
          four = require.resolve("./fixtures/packages/package-with-styles/styles/4.css")

          one = PlanckEnv.themes.stringToId(one)
          two = PlanckEnv.themes.stringToId(two)
          three = PlanckEnv.themes.stringToId(three)
          four = PlanckEnv.themes.stringToId(four)

          expect(PlanckEnv.themes.stylesheetElementForId(one)).toBeNull()
          expect(PlanckEnv.themes.stylesheetElementForId(two)).toBeNull()
          expect(PlanckEnv.themes.stylesheetElementForId(three)).toBeNull()
          expect(PlanckEnv.themes.stylesheetElementForId(four)).toBeNull()

          waitsForPromise ->
            PlanckEnv.packages.activatePackage("package-with-styles")

          runs ->
            expect(PlanckEnv.themes.stylesheetElementForId(one)).not.toBeNull()
            expect(PlanckEnv.themes.stylesheetElementForId(two)).not.toBeNull()
            expect(PlanckEnv.themes.stylesheetElementForId(three)).not.toBeNull()
            expect(PlanckEnv.themes.stylesheetElementForId(four)).not.toBeNull()
            expect($('#jasmine-content').css('font-size')).toBe '3px'

      it "assigns the stylesheet's context based on the filename", ->
        waitsForPromise ->
          PlanckEnv.packages.activatePackage("package-with-styles")

        runs ->
          count = 0

          for styleElement in PlanckEnv.styles.getStyleElements()
            if styleElement.sourcePath.match /1.css/
              expect(styleElement.context).toBe undefined
              count++

            if styleElement.sourcePath.match /2.less/
              expect(styleElement.context).toBe undefined
              count++

            if styleElement.sourcePath.match /3.test-context.css/
              expect(styleElement.context).toBe 'test-context'
              count++

            if styleElement.sourcePath.match /4.css/
              expect(styleElement.context).toBe undefined
              count++

          expect(count).toBe 4

    describe "scoped-property loading", ->
      it "loads the scoped properties", ->
        waitsForPromise ->
          PlanckEnv.packages.activatePackage("package-with-settings")

        runs ->
          expect(PlanckEnv.config.get 'editor.increaseIndentPattern', scope: ['.source.omg']).toBe '^a'

    describe "service registration", ->
      it "registers the package's provided and consumed services", ->
        consumerModule = require "./fixtures/packages/package-with-consumed-services"
        firstServiceV3Disposed = false
        firstServiceV4Disposed = false
        secondServiceDisposed = false
        spyOn(consumerModule, 'consumeFirstServiceV3').andReturn(new Disposable -> firstServiceV3Disposed = true)
        spyOn(consumerModule, 'consumeFirstServiceV4').andReturn(new Disposable -> firstServiceV4Disposed = true)
        spyOn(consumerModule, 'consumeSecondService').andReturn(new Disposable -> secondServiceDisposed = true)

        waitsForPromise ->
          PlanckEnv.packages.activatePackage("package-with-consumed-services")

        waitsForPromise ->
          PlanckEnv.packages.activatePackage("package-with-provided-services")

        runs ->
          expect(consumerModule.consumeFirstServiceV3).toHaveBeenCalledWith('first-service-v3')
          expect(consumerModule.consumeFirstServiceV4).toHaveBeenCalledWith('first-service-v4')
          expect(consumerModule.consumeSecondService).toHaveBeenCalledWith('second-service')

          consumerModule.consumeFirstServiceV3.reset()
          consumerModule.consumeFirstServiceV4.reset()
          consumerModule.consumeSecondService.reset()

          PlanckEnv.packages.deactivatePackage("package-with-provided-services")

          expect(firstServiceV3Disposed).toBe true
          expect(firstServiceV4Disposed).toBe true
          expect(secondServiceDisposed).toBe true

          PlanckEnv.packages.deactivatePackage("package-with-consumed-services")

        waitsForPromise ->
          PlanckEnv.packages.activatePackage("package-with-provided-services")

        runs ->
          expect(consumerModule.consumeFirstServiceV3).not.toHaveBeenCalled()
          expect(consumerModule.consumeFirstServiceV4).not.toHaveBeenCalled()
          expect(consumerModule.consumeSecondService).not.toHaveBeenCalled()

  describe "::deactivatePackage(id)", ->
    afterEach ->
      PlanckEnv.packages.unloadPackages()

    it "calls `deactivate` on the package's main module if activate was successful", ->
      pack = null
      waitsForPromise ->
        PlanckEnv.packages.activatePackage("package-with-deactivate").then (p) -> pack = p

      runs ->
        expect(PlanckEnv.packages.isPackageActive("package-with-deactivate")).toBeTruthy()
        spyOn(pack.mainModule, 'deactivate').andCallThrough()

        PlanckEnv.packages.deactivatePackage("package-with-deactivate")
        expect(pack.mainModule.deactivate).toHaveBeenCalled()
        expect(PlanckEnv.packages.isPackageActive("package-with-module")).toBeFalsy()

        spyOn(console, 'log')
        spyOn(console, 'warn')
        spyOn(console, "error")

      badPack = null
      waitsForPromise ->
        PlanckEnv.packages.activatePackage("package-that-throws-on-activate").then (p) -> badPack = p

      runs ->
        expect(PlanckEnv.packages.isPackageActive("package-that-throws-on-activate")).toBeTruthy()
        spyOn(badPack.mainModule, 'deactivate').andCallThrough()

        PlanckEnv.packages.deactivatePackage("package-that-throws-on-activate")
        expect(badPack.mainModule.deactivate).not.toHaveBeenCalled()
        expect(PlanckEnv.packages.isPackageActive("package-that-throws-on-activate")).toBeFalsy()

    it "does not serialize packages that have not been activated called on their main module", ->
      spyOn(console, 'log')
      spyOn(console, 'warn')
      spyOn(console, "error")
      badPack = null
      waitsForPromise ->
        PlanckEnv.packages.activatePackage("package-that-throws-on-activate").then (p) -> badPack = p

      runs ->
        spyOn(badPack.mainModule, 'serialize').andCallThrough()

        PlanckEnv.packages.deactivatePackage("package-that-throws-on-activate")
        expect(badPack.mainModule.serialize).not.toHaveBeenCalled()

    it "absorbs exceptions that are thrown by the package module's serialize method", ->
      spyOn(console, 'error')

      waitsForPromise ->
        PlanckEnv.packages.activatePackage('package-with-serialize-error')

      waitsForPromise ->
        PlanckEnv.packages.activatePackage('package-with-serialization')

      runs ->
        PlanckEnv.packages.deactivatePackages()
        expect(PlanckEnv.packages.packageStates['package-with-serialize-error']).toBeUndefined()
        expect(PlanckEnv.packages.packageStates['package-with-serialization']).toEqual someNumber: 1
        expect(console.error).toHaveBeenCalled()

    it "absorbs exceptions that are thrown by the package module's deactivate method", ->
      spyOn(console, 'error')

      waitsForPromise ->
        PlanckEnv.packages.activatePackage("package-that-throws-on-deactivate")

      runs ->
        expect(-> PlanckEnv.packages.deactivatePackage("package-that-throws-on-deactivate")).not.toThrow()
        expect(console.error).toHaveBeenCalled()

    it "removes the package's keymaps", ->
      waitsForPromise ->
        PlanckEnv.packages.activatePackage('package-with-keymaps')

      runs ->
        PlanckEnv.packages.deactivatePackage('package-with-keymaps')
        expect(PlanckEnv.keymaps.findKeyBindings(keystrokes:'ctrl-z', target: ($$ -> @div class: 'test-1')[0])).toHaveLength 0
        expect(PlanckEnv.keymaps.findKeyBindings(keystrokes:'ctrl-z', target: ($$ -> @div class: 'test-2')[0])).toHaveLength 0

    it "removes the package's stylesheets", ->
      waitsForPromise ->
        PlanckEnv.packages.activatePackage('package-with-styles')

      runs ->
        PlanckEnv.packages.deactivatePackage('package-with-styles')
        one = require.resolve("./fixtures/packages/package-with-style-sheets-manifest/styles/1.css")
        two = require.resolve("./fixtures/packages/package-with-style-sheets-manifest/styles/2.less")
        three = require.resolve("./fixtures/packages/package-with-style-sheets-manifest/styles/3.css")
        expect(PlanckEnv.themes.stylesheetElementForId(one)).not.toExist()
        expect(PlanckEnv.themes.stylesheetElementForId(two)).not.toExist()
        expect(PlanckEnv.themes.stylesheetElementForId(three)).not.toExist()

    it "removes the package's scoped-properties", ->
      waitsForPromise ->
        PlanckEnv.packages.activatePackage("package-with-settings")

      runs ->
        expect(PlanckEnv.config.get 'editor.increaseIndentPattern', scope: ['.source.omg']).toBe '^a'
        PlanckEnv.packages.deactivatePackage("package-with-settings")
        expect(PlanckEnv.config.get 'editor.increaseIndentPattern', scope: ['.source.omg']).toBeUndefined()

    it "invokes ::onDidDeactivatePackage listeners with the deactivated package", ->
      waitsForPromise ->
        PlanckEnv.packages.activatePackage("package-with-main")

      runs ->
        deactivatedPackage = null
        PlanckEnv.packages.onDidDeactivatePackage (pack) -> deactivatedPackage = pack
        PlanckEnv.packages.deactivatePackage("package-with-main")
        expect(deactivatedPackage.name).toBe "package-with-main"

  describe "::activate()", ->
    beforeEach ->
      jasmine.snapshotDeprecations()
      spyOn(console, 'warn')
      spyOn(console, "error")
      PlanckEnv.packages.loadPackages()

      loadedPackages = PlanckEnv.packages.getLoadedPackages()
      expect(loadedPackages.length).toBeGreaterThan 0

    afterEach ->
      PlanckEnv.packages.deactivatePackages()
      PlanckEnv.packages.unloadPackages()
      jasmine.restoreDeprecationsSnapshot()

    it "activates all the packages, and none of the themes", ->
      packageActivator = spyOn(PlanckEnv.packages, 'activatePackages')
      themeActivator = spyOn(PlanckEnv.themes, 'activatePackages')

      PlanckEnv.packages.activate()

      expect(packageActivator).toHaveBeenCalled()
      expect(themeActivator).toHaveBeenCalled()

      packages = packageActivator.mostRecentCall.args[0]
      expect(['nylas']).toContain(pack.getType()) for pack in packages

      themes = themeActivator.mostRecentCall.args[0]
      expect(['theme']).toContain(theme.getType()) for theme in themes

    it "refreshes the database after activating packages with models", ->
      spyOn(DatabaseStore, "refreshDatabaseSchema")
      package2 = PlanckEnv.packages.loadPackage('package-with-models')
      PlanckEnv.packages.activatePackages([package2])
      expect(DatabaseStore.refreshDatabaseSchema).toHaveBeenCalled()
      expect(DatabaseStore.refreshDatabaseSchema.calls.length).toBe 1

    it "calls callbacks registered with ::onDidActivateInitialPackages", ->
      package1 = PlanckEnv.packages.loadPackage('package-with-main')
      package2 = PlanckEnv.packages.loadPackage('package-with-index')
      package3 = PlanckEnv.packages.loadPackage('package-with-activation-commands')
      spyOn(PlanckEnv.packages, 'getLoadedPackages').andReturn([package1, package2])

      activateSpy = jasmine.createSpy('activateSpy')
      PlanckEnv.packages.onDidActivateInitialPackages(activateSpy)

      PlanckEnv.packages.activate()
      waitsFor -> activateSpy.callCount > 0
      runs ->
        jasmine.unspy(PlanckEnv.packages, 'getLoadedPackages')
        expect(package1 in PlanckEnv.packages.getActivePackages()).toBe true
        expect(package2 in PlanckEnv.packages.getActivePackages()).toBe true
        expect(package3 in PlanckEnv.packages.getActivePackages()).toBe false

  describe "::enablePackage(id) and ::disablePackage(id)", ->
    describe "with packages", ->
      it "enables a disabled package", ->
        spyOn(DatabaseStore, "refreshDatabaseSchema")
        packageName = 'package-with-main'
        PlanckEnv.config.pushAtKeyPath('core.disabledPackages', packageName)
        PlanckEnv.packages.observeDisabledPackages()
        expect(PlanckEnv.config.get('core.disabledPackages')).toContain packageName

        pack = PlanckEnv.packages.enablePackage(packageName)
        loadedPackages = PlanckEnv.packages.getLoadedPackages()
        activatedPackages = null
        waitsFor ->
          activatedPackages = PlanckEnv.packages.getActivePackages()
          activatedPackages.length > 0

        runs ->
          expect(loadedPackages).toContain(pack)
          expect(activatedPackages).toContain(pack)
          expect(DatabaseStore.refreshDatabaseSchema).not.toHaveBeenCalled()
          expect(PlanckEnv.config.get('core.disabledPackages')).not.toContain packageName

      it 'refreshes the DB when loading a package with models', ->
        spyOn(DatabaseStore, "refreshDatabaseSchema")
        packageName = "package-with-models"
        PlanckEnv.config.pushAtKeyPath('core.disabledPackages', packageName)
        PlanckEnv.packages.observeDisabledPackages()
        PlanckEnv.config.removeAtKeyPath("core.disabledPackages", packageName)
        expect(DatabaseStore.refreshDatabaseSchema).toHaveBeenCalled()
        expect(DatabaseStore.refreshDatabaseSchema.calls.length).toBe 1

      it "disables an enabled package", ->
        packageName = 'package-with-main'
        waitsForPromise ->
          PlanckEnv.packages.activatePackage(packageName)

        runs ->
          PlanckEnv.packages.observeDisabledPackages()
          expect(PlanckEnv.config.get('core.disabledPackages')).not.toContain packageName

          pack = PlanckEnv.packages.disablePackage(packageName)

          activatedPackages = PlanckEnv.packages.getActivePackages()
          expect(activatedPackages).not.toContain(pack)
          expect(PlanckEnv.config.get('core.disabledPackages')).toContain packageName

      it "returns null if the package cannot be loaded", ->
        spyOn(console, 'warn')
        spyOn(console, "error")
        expect(PlanckEnv.packages.enablePackage("this-doesnt-exist")).toBeNull()
        expect(console.warn.callCount).toBe 1

    describe "with themes", ->
      didChangeActiveThemesHandler = null

      beforeEach ->
        theme_dir = path.resolve(__dirname, '../internal_packages')
        PlanckEnv.packages.packageDirPaths.unshift(theme_dir)
        waitsForPromise ->
          PlanckEnv.themes.activateThemes()

      afterEach ->
        PlanckEnv.themes.deactivateThemes()

      it "enables and disables a theme", ->
        packageName = 'theme-with-package-file'

        expect(PlanckEnv.config.get('core.themes')).not.toContain packageName
        expect(PlanckEnv.config.get('core.disabledPackages')).not.toContain packageName

        # enabling of theme
        pack = PlanckEnv.packages.enablePackage(packageName)

        waitsFor ->
          pack in PlanckEnv.packages.getActivePackages()

        runs ->
          expect(PlanckEnv.config.get('core.themes')).toContain packageName
          expect(PlanckEnv.config.get('core.disabledPackages')).not.toContain packageName

          didChangeActiveThemesHandler = jasmine.createSpy('didChangeActiveThemesHandler')
          didChangeActiveThemesHandler.reset()
          PlanckEnv.themes.onDidChangeActiveThemes didChangeActiveThemesHandler

          pack = PlanckEnv.packages.disablePackage(packageName)

        waitsFor ->
          didChangeActiveThemesHandler.callCount is 1

        runs ->
          expect(PlanckEnv.packages.getActivePackages()).not.toContain pack
          expect(PlanckEnv.config.get('core.themes')).not.toContain packageName
          expect(PlanckEnv.config.get('core.themes')).not.toContain packageName
          expect(PlanckEnv.config.get('core.disabledPackages')).not.toContain packageName

  describe 'packages with models and tasks', ->
    beforeEach ->
      PlanckEnv.packages.deactivatePackages()
      PlanckEnv.packages.unloadPackages()

    it 'registers objects on load', ->
      withModels = PlanckEnv.packages.loadPackage("package-with-models")
      withoutModels = PlanckEnv.packages.loadPackage("package-with-main")
      expect(withModels.declaresNewDatabaseObjects).toBe true
      expect(withoutModels.declaresNewDatabaseObjects).toBe false
      expect(PlanckEnv.packages.packagesWithDatabaseObjects.length).toBe 1
      expect(PlanckEnv.packages.packagesWithDatabaseObjects[0]).toBe withModels
