Flixel Unit Tests
-----------------

This is a unit test project using [munit](https://github.com/massiveinteractive/MassiveUnit). It's good practice to add tests for fixed bugs or new features.

TODO Make sure the unit tests are automatically run on GitHub Actions.

There's a 1:1 mapping between `.hx` files in `source/` and the unit test project - tests for `funkin.Conductor` go into `funkin.ConductorTest` etc.

### Building

Run one of the `test-*.hxml` files in this directory to run the tests on that specific target, e.g. `haxe test-cpp.hxml`. Currently supported are:

- `web` (HTML5)
- `cpp` (Native)

Alternatively, this can be done from within Visual Studio Code - (`F1` -> `Tasks: Run Task` -> Choose the target to test).

#### Adding Tests

- Run `haxelib run munit create com.FooBarTest -for com.Foo`
- Use `@:allow(full.package.name.ClassName)` to allow a test class to call private functions.
- Use `mockatoo.Mockatoo.mock(ClassName)` to mock a class. See [Mockatoo docs](https://github.com/misprintt/mockatoo).

#### Functions

- `@Before` functions are named `before()`
- Each `@Test` function starts with `test` and describes what exactly it tests. This can lead to long function names like `FlxEmitter#testStartShouldNotReviveMembers()` and serves as self-documentation.
- Another thing that helps with self-documentation is adding a comment for tests that are related an issue on GitHub.

	```haxe
	@Test // #1203
	function testColorWithAlphaComparison()
	```

### `FunkinTest` base class

Test classes extend `FunkinTest`, which is a base class with some utility functions for testing.

### `step()`

`step()` advances the `FlxGame` exactly one step. This is useful for tests that depend on game time advancing / `FlxGame#step()` being executed, such as physics of `add()`ed objects, state switches, or just time passing for tweens or timers.

There are two parameters:
- `steps` - specifies the amount of steps to advance (defaults to 1)
- `callback` - an optional callback function that is executed after each step

### `testDestroy()`

`testDestroy()` tests whether an `IFlxDestroyable` can safely be `destroy()`ed more than once (null reference errors are fairly common here). For this, `destroyable` has to be set during `before()` of the test class.

### Null Safety

Append each test class with `@:nullSafety` to prevent crash bugs while developing.

Note that `Assert.isNotNull(target)` is considered a vlid
