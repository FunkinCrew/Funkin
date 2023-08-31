package;

import openfl.Lib;
import flixel.FlxGame;
import flixel.FlxState;
import massive.munit.TestRunner;
import massive.munit.client.HTTPClient;
import massive.munit.client.SummaryReportClient;
import funkin.util.logging.CrashHandler;
import funkin.util.FileUtil;

/**
 * Auto generated Test Application.
 * Refer to munit command line tool for more information (haxelib run munit)
 */
@:nullSafety
class TestMain
{
  /**
   * If true, include a report with each ignored test and their descriptions.
   */
  static final INCLUDE_IGNORED_REPORT:Bool = false;

  static final COVERAGE_FOLDER:String = "../../../report";

  static function main()
  {
    new TestMain();
  }

  public function new()
  {
    try
    {
      CrashHandler.initialize();

      // Flixel was not designed for unit testing so we can only have one instance for now.
      Lib.current.stage.addChild(new FlxGame(640, 480, FlxState, 60, 60, true));

      var suites = new Array<Class<massive.munit.TestSuite>>();
      suites.push(TestSuite);

      #if MCOVER
      // Print individual test results alongside coverage results for each test class,
      // as well as a final coverage report for the entire test suite.
      var innerClient = new massive.munit.client.RichPrintClient(INCLUDE_IGNORED_REPORT);
      var client = new mcover.coverage.munit.client.MCoverPrintClient(innerClient);
      // Print final test results alongside detailed coverage results for the test suite.
      var httpClient = new HTTPClient(new mcover.coverage.munit.client.MCoverSummaryReportClient());
      // NOTE: You can also create a custom ICoverageTestResultClient implementation

      // Output coverage in LCOV format.
      FileUtil.createDirIfNotExists(COVERAGE_FOLDER);
      mcover.coverage.MCoverage.getLogger().addClient(new mcover.coverage.client.LcovPrintClient("Funkin' Coverage Report", '${COVERAGE_FOLDER}/lcov.info'));
      #else
      // Print individual test results.
      var client = new massive.munit.client.RichPrintClient(INCLUDE_IGNORED_REPORT);
      // Print final test suite results.
      var httpClient = new HTTPClient(new SummaryReportClient());
      #end

      var runner = new TestRunner(client);
      runner.addResultClient(httpClient);

      runner.completionHandler = completionHandler;
      runner.run(suites);
    }
    catch (e)
    {
      trace('UNCAUGHT EXCEPTION');
      trace(e);
    }
  }

  /**
   * updates the background color and closes the current browser
   * for flash and html targets (useful for continuos integration servers)
   */
  function completionHandler(successful:Bool):Void
  {
    try
    {
      #if flash
      openfl.external.ExternalInterface.call("testResult", successful);
      #elseif js
      js.Lib.eval("testResult(" + successful + ");");
      #elseif sys
      Sys.exit(successful ? 0 : 1);
      #end
    }
    // if run from outside browser can get error which we can ignore
    catch (e:Dynamic) {}
  }
}
