import Account "account";
import TrieMap "mo:base/TrieMap";
import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Http "http";
import Float "mo:base/Float";
import Array "mo:base/Array";
import Result "mo:base/Result";

actor class DAO() {
  //Level 6, my own project
  let ledger : TrieMap.TrieMap<Account.Account, Nat> = TrieMap.TrieMap(Account.accountsEqual, Account.accountsHash);
  var nextProductId : Nat = 1;

  public type Result<A, B> = Result.Result<A, B>;
  public type HashMap<A, B> = HashMap.HashMap<A, B>;

  public type ProductOk = {
    #ProductAdded;
    #ProductUpdated;
    #ProductRemoved;
  };

  public type ProductErr = {
    #ProductNotFound;
  };

  public type BuyStuff = {
    id : Nat;
    name : Text;
    price : Nat;
    description : Text;
    image : Text;
    quantity : Nat;
    averageRating : Float;
    numberOfRatings : Nat;
  };

  public type RateProduct = {
    name : Text;
    rating : Nat;
  };

  public type rateProductOk = {
    #ProductRated;
  };

  public type rateProductErr = {
    #ProductNotFound;
    #NotPurchased;
  };

  public type buyStuffResult = Result<BuyStuff, Text>;

  public type rateProductResult = Result<rateProductOk, rateProductErr>;

  public type productResult = Result<ProductOk, ProductErr>;

  public type Images = {
    urlLogo : ?Text;
    urlBanner : ?Text;
  };

  public type Socials = {
    GitHub : ?Text;
    Linkedin : ?Text;
    OpenChat : ?Text;
  };

  let MyProjectSocials : Socials = {
    GitHub = ?"https://github.com/proappple123/level_6";
    OpenChat = ?"https://oc.app/user/cl2ig-wqaaa-aaaar-aynca-cai";
    Linkedin = ?"https://www.linkedin.com/in/yong-zhi-m-9a5350219/";
  };

  public query func getName_MBC() : async Text {
    return "Yong Zhi's Shop";
  };

  public query func getDescription_MBC() : async Text {
    return "This is an e-shop where user is able to buy stuffs using the token";
  };

  public query func getAuthor_MBC() : async Text {
    return "Yong Zhi";
  };

  public query func getImages_MBC() : async Images {
    return {
      urlLogo = ?"https://ibb.co/zJYt6JG";
      urlBanner = ?"https://ibb.co/zJYt6JG";
    };
  };

  public query func getSocialsAuthor_MBC() : async Socials {
    return MyProjectSocials;
  };

  public query func getSocialsProject_MBC() : async Socials {
    return MyProjectSocials;
  };

  let products : TrieMap.TrieMap<Text, BuyStuff> = TrieMap.TrieMap(Text.equal, Text.hash);

  public shared func addProduct(name : Text, price : Nat, description : Text, image : Text, rating : Bool) : async productResult {
    let product = {
      id = nextProductId;
      name = name;
      price = price;
      description = description;
      image = image;
      quantity = 0;
      averageRating = 0.0;
      numberOfRatings = 0;
    };
    products.put(name, product);
    nextProductId += 1;
    return #ok(#ProductAdded);
  };

  public func updateProduct(name : Text, price : Nat, description : Text, image : Text) : async productResult {
    let product = {
      name = name;
      price = price;
      description = description;
      image = image;
    };

    let productWithRating = {
      id = nextProductId;
      name = product.name;
      price = product.price;
      description = product.description;
      image = product.image;
      quantity = 0;
      averageRating = 0.0;
      numberOfRatings = 0;
    };

    products.put(name, productWithRating);
    return #ok(#ProductUpdated);

  };

  public func removeProduct(name : Text) : async productResult {
    products.delete(name);
    return #ok(#ProductRemoved);
  };

  public query func getProduct(name : Text) : async ?BuyStuff {
    return products.get(name);
  };

  public query func getAllProducts() : async [BuyStuff] {
    return Iter.toArray(products.vals());
  };

  public query func getNumberOfProducts() : async Nat {
    return products.size();
  };

  public shared ({ caller }) func buyProduct(name : Text) : async buyStuffResult {
    let product = switch (products.get(name)) {
      case (null) { return #err("Product not found") };
      case (?some) { some };
    };
    let defaultAccount = { owner = caller; subaccount = null };
    switch (ledger.get(defaultAccount)) {
      case (null) { return #err("Not enough balance") };
      case (?some) {
        if (some < product.price) {
          return #err("Not enough balance");
        };
        ledger.put(defaultAccount, some - product.price);
        return #ok(product);
      };
    };
  };

  func hasUserPurchased(caller : Principal, productName : Text) : Bool {
    let defaultAccount = { owner = caller; subaccount = null };
    switch (ledger.get(defaultAccount)) {
      case (null) { return false };
      case (?some) {
        let product = switch (products.get(productName)) {
          case (null) { return false };
          case (?some) { some };
        };
        return some >= product.price;
      };
    };
  };

  public shared ({ caller }) func rateProduct(name : Text, rating : Nat) : async rateProductResult {
    if (not hasUserPurchased(caller, name)) {
      return #err(#ProductNotFound);
    };

    let productOpt = products.get(name);
    switch (productOpt) {
      case (null) {
        return #err(#NotPurchased);
      };
      case (?product) {
        let newNumberOfRatings = product.numberOfRatings + 1;
        let newAverageRating = (product.averageRating * Float.fromInt(product.numberOfRatings) + Float.fromInt(rating)) / Float.fromInt(newNumberOfRatings);

        let updatedProduct = {
          id = nextProductId;
          name = product.name;
          price = product.price;
          description = product.description;
          image = product.image;
          quantity = product.quantity;
          averageRating = newAverageRating;
          numberOfRatings = newNumberOfRatings;
        };

        products.put(name, updatedProduct);
        return #ok(#ProductRated);
      };
    };
  };

  public shared ({ caller }) func getMyProducts() : async [BuyStuff] {
    var myProducts = Buffer.Buffer<BuyStuff>(0);
    for (product in products.vals()) {
      if (hasUserPurchased(caller, product.name)) {
        myProducts.add(product);
      };
    };
    return Buffer.toArray(myProducts);
  };

  let carts : TrieMap.TrieMap<Principal, [BuyStuff]> = TrieMap.TrieMap(Principal.equal, Principal.hash);

  public shared ({ caller }) func currentCart() : async [BuyStuff] {
    let cartOpt = carts.get(caller);
    switch (cartOpt) {
      case (null) {
        return [];
      };
      case (?cart) {
        return cart;
      };
    };
  };

  public shared ({ caller }) func addToCart(name : Text) : async [BuyStuff] {
    // Step 1: Retrieve the Product
    let productOpt = products.get(name);
    switch (productOpt) {
      case (null) {
        // If the product is not found, return an empty list or handle the error
        return [];
      };
      case (?product) {
        // Step 2: Retrieve or Initialize the Cart
        let cartOpt = carts.get(caller);
        let updatedCart = switch (cartOpt) {
          case (null) {
            // If the cart does not exist, create a new one with the product
            [product];
          };
          case (?existingCart) {
            // If the cart exists, add the product to it
            let newCart = Buffer.fromArray<BuyStuff>(existingCart);
            newCart.add(product);
            Buffer.toArray(newCart);
          };
        };

        // Step 3: Update the Cart in the TrieMap and Return
        carts.put(caller, updatedCart); // Update the cart in TrieMap
        return updatedCart; // Return the updated cart
      };
    };
  };

  public type CartUpdateResult = Result<[BuyStuff], Text>;

  public shared ({ caller }) func removeFromCart(name : Text) : async CartUpdateResult {

    let productOpt = products.get(name);
    switch (productOpt) {
      case (null) {
        return #err("Product not found");
      };
      case (?product) {
        // Retrieve the cart
        let cartOpt = carts.get(caller);
        switch (cartOpt) {
          case (null) {
            return #err("Cart not found");
          };
          case (?existingCart) {
            // Use filter to remove the product
            let updatedCart = Array.filter<BuyStuff>(
              existingCart,
              func(product) : Bool {
                return product.name != name; // Keep all products not matching the name
              },
            );

            // Update the cart in TrieMap and return
            carts.put(caller, updatedCart);
            return #ok(updatedCart);
          };
        };
      };
    };
  };

  public shared ({ caller }) func buyCurrentCart() : async CartUpdateResult {
    let cartOpt = carts.get(caller);
    switch (cartOpt) {
      case (null) {
        return #err("Product not found.");
      };
      case (?existingCart) {
        let totalPrice = Array.foldLeft<BuyStuff, Nat>(
          existingCart,
          0,
          func(total, product) : Nat {
            return total + product.price;
          },
        );
        let defaultAccount = { owner = caller; subaccount = null };
        switch (ledger.get(defaultAccount)) {
          case (null) {
            return #err("Not enough balance");
          };
          case (?balance) {
            if (balance < totalPrice) {
              return #err("Not enough balance");
            };
            ledger.put(defaultAccount, balance - totalPrice);
            carts.delete(caller);
            return #ok([]);
          };
        };
      };
    };
  };

  public type MintResult = Result<(), Text>;
  let authorizedPrincipals : TrieMap.TrieMap<Principal, Bool> = TrieMap.TrieMap(Principal.equal, Principal.hash);

  func isAuthorized(principal : Principal) : Bool {
    switch (authorizedPrincipals.get(principal)) {
      case (null) { false };
      case (?isAuth) { isAuth };
    };
  };

  public shared ({ caller }) func mint(balance : Nat, principal : Principal) : async MintResult {
    if (isAuthorized(caller)) {
      let defaultAccount = { owner = principal; subaccount = null };
      switch (ledger.get(defaultAccount)) {
        case (null) {
          ledger.put(defaultAccount, balance);
        };
        case (?user) {
          ledger.put(defaultAccount, user + balance);
        };
      };
      return #ok(());
    } else {
      return #err("Not authorized");
    };
  };

  public func authorize(principal : Principal) : async () {
    authorizedPrincipals.put(principal, true);
  };

  public func deauthorize(principal : Principal) : async () {
    authorizedPrincipals.delete(principal);
  };

  public shared ({ caller }) func getBalance(principal : Principal) : async ?Nat {
    let defaultAccount = { owner = principal; subaccount = null };
    return ledger.get(defaultAccount);
  };

  public shared (msg) func callerPrincipal() : async Principal {
    return msg.caller;
  };
};
