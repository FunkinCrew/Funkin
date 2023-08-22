package funkin.util.tools;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import funkin.util.tools.ArrayTools;

@:access(funkin.util.tools.ArrayTools)
class ArraySortToolsTest extends FunkinTest
{
  public function new()
  {
    super();
  }

  @BeforeClass
  public function beforeClass() {}

  @AfterClass
  public function afterClass() {}

  @Before
  public function setup() {}

  @After
  public function tearDown() {}

  @Test
  public function testMergeSort()
  {
    var testArray:Array<Int> = [5, 4, 3, 2, 1];

    function compare(a:Int, b:Int)
    {
      return a - b;
    }

    ArraySortTools.mergeSort(testArray, compare);

    Assert.areEqual(testArray[0], 1);
    Assert.areEqual(testArray[1], 2);
    Assert.areEqual(testArray[2], 3);
    Assert.areEqual(testArray[3], 4);
    Assert.areEqual(testArray[4], 5);

    var testArray2:Array<Int> = [9, 6, 3, 12];

    ArraySortTools.mergeSort(testArray2, compare);

    Assert.areEqual(testArray2[0], 3);
    Assert.areEqual(testArray2[1], 6);
    Assert.areEqual(testArray2[2], 9);
    Assert.areEqual(testArray2[3], 12);

    // Just make sure these don't crash.
    ArraySortTools.mergeSort([], compare);
    ArraySortTools.mergeSort(null, compare);
    ArraySortTools.mergeSort([], null);
    ArraySortTools.mergeSort(null, null);

    // Make sure these throw an exception.
    try
    {
      ArraySortTools.mergeSort(testArray, null);

      Assert.fail("Function should have thrown an exception.");
    }
    catch (e)
    {
      Assert.areEqual("No comparison function provided.", e);
    }
  }

  @Test
  public function testQuickSort()
  {
    var testArray:Array<Int> = [5, 4, 3, 2, 1];

    function compare(a:Int, b:Int)
    {
      return a - b;
    }

    ArraySortTools.quickSort(testArray, compare);

    Assert.areEqual(testArray[0], 1);
    Assert.areEqual(testArray[1], 2);
    Assert.areEqual(testArray[2], 3);
    Assert.areEqual(testArray[3], 4);
    Assert.areEqual(testArray[4], 5);

    var testArray2:Array<Int> = [9, 6, 3, 12];

    ArraySortTools.quickSort(testArray2, compare);

    Assert.areEqual(testArray2[0], 3);
    Assert.areEqual(testArray2[1], 6);
    Assert.areEqual(testArray2[2], 9);
    Assert.areEqual(testArray2[3], 12);

    // Just make sure these don't crash.
    ArraySortTools.quickSort([], compare);
    ArraySortTools.quickSort(null, compare);
    ArraySortTools.quickSort([], null);
    ArraySortTools.quickSort(null, null);

    // Make sure these throw an exception.
    try
    {
      ArraySortTools.quickSort(testArray, null);

      Assert.fail("Function should have thrown an exception.");
    }
    catch (e)
    {
      Assert.areEqual("No comparison function provided.", e);
    }
  }

  @Test
  public function testInsertionSort()
  {
    var testArray:Array<Int> = [5, 4, 3, 2, 1];

    function compare(a:Int, b:Int)
    {
      return a - b;
    }

    ArraySortTools.insertionSort(testArray, compare);

    Assert.areEqual(testArray[0], 1);
    Assert.areEqual(testArray[1], 2);
    Assert.areEqual(testArray[2], 3);
    Assert.areEqual(testArray[3], 4);
    Assert.areEqual(testArray[4], 5);

    var testArray2:Array<Int> = [9, 6, 3, 12];

    ArraySortTools.insertionSort(testArray2, compare);

    Assert.areEqual(testArray2[0], 3);
    Assert.areEqual(testArray2[1], 6);
    Assert.areEqual(testArray2[2], 9);
    Assert.areEqual(testArray2[3], 12);

    // Just make sure these don't crash.
    ArraySortTools.insertionSort([], compare);
    ArraySortTools.insertionSort(null, compare);
    ArraySortTools.insertionSort([], null);
    ArraySortTools.insertionSort(null, null);

    // Make sure these throw an exception.
    try
    {
      ArraySortTools.insertionSort(testArray, null);

      Assert.fail("Function should have thrown an exception.");
    }
    catch (e)
    {
      Assert.areEqual("No comparison function provided.", e);
    }
  }
}
