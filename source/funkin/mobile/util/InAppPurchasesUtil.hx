package funkin.mobile.util;

#if android
import iap.IAP;

/**
 * Utility class for managing in-app purchases in a mobile application.
 * This class provides functions to initialize the in-app purchase system,
 * handle purchase events, and manage the purchase flow for different types
 * of in-app products, including consumables and non-consumables.
 */
class InAppPurchasesUtil
{
  /**
   * The public key used for verifying in-app purchases, this key is used to ensure the integrity and authenticity of the purchase data.
   */
  static final PUBLIC_KEY:String = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvkjukXVNVifxcwvCdntLoVPlMo4H0y232w+7FJCyDLIE39Sif6peAZzRJx5qppCwKhEy0BPp8DNcPCo+KeuYjOroXgPGdwZ6Zr8Cwlrs+xKba2Yt0qr98VhF4PjjJMaDbrLCxtsXEtcpKfItu+Z7m6+4+R5HLP3lvUvK5JynvQ79mct0amKM5WLtnGGDF/cUHaj3prw745SmOpXawTjb43AAIvwWTvEPnFYsoIXodU+4KAm5QIS4FM55HpwXPs8McJFQouo8LaSzYu8SYwRsHBOZpAGgszDIK40gIUmKTe3Ca2Vd77Ib+YP1+EgHJywfuYfC5NAzQRatEX0uDLZ8fwIDAQAB";

  /**
   * A static final array containing the product IDs for fetching product details.
   */
  static final FETCH_PRODUCT_DETAILS_IDS:Array<String> = ['test_product_0'];

  /**
   * A static variable that holds an array of currently loaded product details for in-app purchases.
   */
  public static var currentLoadedProductDetails:Array<iap.android.IAPProductDetails> = [];

  /**
   * Initializes the in-app purchases utility.
   */
  public static function init():Void
  {
    IAP.onSetup.add(function(success:Bool):Void {
      if (success) IAP.queryProductDetails(FETCH_PRODUCT_DETAILS_IDS);

      trace(success ? 'IAP Successfully initialized!' : 'IAP Initialization Failure!');
    });

    IAP.onDebugLog.add(function(message:String):Void {
      trace(message);
    });

    #if android
    IAP.onQueryProductDetails.add(function(products:Array<iap.android.IAPProductDetails>):Void {
      if (products != null && products.length > 0)
      {
        currentLoadedProductDetails = products;

        for (product in currentLoadedProductDetails)
        {
          trace("Product Details found: " + product.title);
        }
      }
      else
      {
        trace("No products found.");
      }
    });
    #end

    IAP.init(PUBLIC_KEY);
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
      if (product.productId == id)
      {
        IAP.purchase(product);

        return;
      }
    }

    trace("Didn\'t Found Product Details for ID: " + id);
  }
}
#end
