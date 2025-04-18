package funkin.mobile.util;

#if FEATURE_IAP
import extension.iapcore.android.IAPAndroid;
import extension.iapcore.android.IAPProductDetails;
import extension.iapcore.android.IAPPurchase;
import extension.iapcore.android.IAPResponseCode;

/**
 * Utility class for managing in-app purchases in a mobile application.
 * This class provides functions to initialize the in-app purchase system,
 * handle purchase events, and manage the purchase flow for different types
 * of in-app products, including consumables and non-consumables.
 */
class InAppPurchasesUtil
{
  /**
   * A static final array containing the product IDs for fetching product details.
   */
  static final FETCH_PRODUCT_DETAILS_IDS:Array<String> = ['test_product_0'];

  /**
   * A static variable that holds an array of currently loaded product details for in-app purchases.
   */
  public static var currentLoadedProductDetails:Array<IAPProductDetails> = [];

  /**
   * Initializes the in-app purchases utility.
   */
  public static function init():Void
  {
    IAPAndroid.onLog.add(function(message:String):Void {
      logMessage(message);
    });

    IAPAndroid.onBillingSetupFinished.add(function(code:IAPResponseCode, message:String):Void {
      if (message != null && message.length > 0) logMessage('IAP Setup finished with code "$code" "$message"!');
      else
      {
        logMessage('IAP Setup finished with code "$code"!');
      }

      if (code == IAPResponseCode.OK)
      {
        IAPAndroid.queryPurchases();

        IAPAndroid.queryProductDetails(FETCH_PRODUCT_DETAILS_IDS);
      }
    });

    IAPAndroid.onBillingServiceDisconnected.add(function():Void {
      logMessage("IAP Billing service disconnected!");
    });

    IAPAndroid.onProductDetailsResponse.add(function(code:IAPResponseCode, productDetails:Array<IAPProductDetails>):Void {
      logMessage('IAP Product details responded with code "$code", $productDetails');

      currentLoadedProductDetails = productDetails;

      for (productDetails in currentLoadedProductDetails)
      {
        logMessage('IAP Product details with title: ${productDetails.getTitle()}');
      }
    });

    IAPAndroid.onQueryPurchasesResponse.add(function(code:IAPResponseCode, purchases:Array<IAPPurchase>):Void {
      logMessage('IAP Query purchases responded with code "$code", $purchases');
    });

    IAPAndroid.onPurchasesUpdated.add(function(code:IAPResponseCode, purchases:Array<IAPPurchase>):Void {
      logMessage('IAP Purchases updated response with code "$code", $purchases');
    });

    IAPAndroid.init();

    IAPAndroid.startConnection();
  }

  /**
   * Initiates the purchase process for the specified item.
   *
   * @param id The identifier of the item to be purchased.
   */
  public static function purchase(id:String):Void
  {
    for (product in currentLoadedProductDetails)
    {
      if (product.getProductId() == id)
      {
        logMessage('Lunching purchase flow for ${product.getTitle()}');

        IAPAndroid.launchPurchaseFlow(product);

        return;
      }
      else
      {
        logMessage('Current ${product.getProductId()} doesnt match ${id}');
      }
    }

    logMessage("Didn\'t Found Product Details for ID: " + id);
  }

  @:noCompletion
  private static function logMessage(message:String):Void
  {
    #if android
    android.widget.Toast.makeText(message, android.widget.Toast.LENGTH_SHORT);
    #end

    trace(message);
  }
}
#end
