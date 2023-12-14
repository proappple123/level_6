import { level_6_backend } from "../../declarations/level_6_backend";
import { AuthClient } from "@dfinity/auth-client";

function loadHomePage() {
  const contentDiv = document.getElementById("content");
  contentDiv.innerHTML = `
    <h1>Welcome to DFINITY E-Commerce</h1>
    <button id="login-button">Login with Internet Identity</button>
    <button id="cart-button">View Cart</button>`;

    document.getElementById("login-button").addEventListener("click", login);
    document.getElementById("cart-button").addEventListener("click", currentCart);
}

async function login() {
  const authClient = await AuthClient.create();
  authClient.login({
      identityProvider: 'https://identity.ic0.app', 
      onSuccess: async () => {
          const identity = authClient.getIdentity();
          const principalId = identity.getPrincipal().toString();
          console.log("Logged in as:", principalId);
      },
      onError: (error) => {
          console.error("Login failed:", error);
      }
  });
}


document.getElementById("add-product-form").addEventListener("submit", async (e) => {
    e.preventDefault();
    const name = document.getElementById("product-name").value;
    const price = Number(document.getElementById("product-price").value);
    const description = document.getElementById("product-description").value;
    const image = document.getElementById("product-image").value;

    const result = await level_6_backend.addProduct(
      name,
      price,
      description,
      image,
      false
    );
    alert(`Added product ${name}`);
  });

  async function addToCart(productName){
    try{
    const result = await level_6_backend.addToCart(productName);
    alert(`Added product ${productName} to cart`, result);
    console.log('success');
    } catch(err){
      alert(err);
    }
  }

  async function currentCart(){
    try{
      const result = await level_6_backend.currentCart();
      alert(`Current cart: ${result}`);
    } catch(err){
      alert(err);
    }
  }

  async function loadProductPage() {
    const contentDiv = document.getElementById("product");
    contentDiv.innerHTML = `
      <h1>Our Products</h1>
      <div class="container">
        <div id="product-list">
        </div>
      </div>`;
  
    const productListDiv = document.getElementById("product-list");
    const products = await level_6_backend.getAllProducts();
  
    products.forEach((product) => {
      const productHtml = `
        <div class="product-item">
        <img src="${product.image}" alt="${product.name}" />
          <p>${product.name}</p>
          <p>${product.description}</p>
          <p>${product.price}</p>
          <p>${product.averageRating}</p>
          <button class="add-to-cart-button" data-name="${product.name}">Add to Cart</button>
        </div>`;
  
      productListDiv.innerHTML += productHtml; 
    });

    document.querySelectorAll(".add-to-cart-button").forEach((button =>{
      button.addEventListener("click", (e) => {
        const productName = e.target.getAttribute("data-name");
        addToCart(productName);
        console.log(productName);
      });
    }))
  }
  


  

document.getElementById("nav-home").addEventListener("click", loadHomePage);
document.getElementById("nav-products")
  .addEventListener("click", loadProductPage);

loadHomePage();
