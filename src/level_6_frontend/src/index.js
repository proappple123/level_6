import { level_6_backend } from "../../declarations/level_6_backend";
import { AuthClient } from "@dfinity/auth-client";

let isLoggedIn = false;

function loadHomePage() {
  const contentDiv = document.getElementById("content");
  contentDiv.innerHTML = `
    <h1>Welcome to DFINITY E-Commerce</h1>
    <button id="login-button">Login with Internet Identity</button>
    <button id="logout-button">Logout</button>
    <button id="cart-button">View Cart</button>
    `;

  document.getElementById("login-button").addEventListener("click", login);
  document.getElementById("logout-button").addEventListener("click", logout);
  document.getElementById("cart-button").addEventListener("click", currentCart);
}

async function login() {
  const authClient = await AuthClient.create();
  authClient.login({
    identityProvider: "https://identity.ic0.app",
    onSuccess: async () => {
      const identity = authClient.getIdentity();
      const principalId = identity.getPrincipal().toString();
      console.log("Logged in as:", principalId);
      isLoggedIn = true;
      updateLoginButton();
    },
    onError: (error) => {
      console.error("Login failed:", error);
    },
  });
}

async function logout(){
  const authClient = await AuthClient.create();
  authClient.logout();
  isLoggedIn = false;
  updateLoginButton();
  console.log("Logged out");
}

async function updateLoginButton(){
  const loginBtn = document.getElementById("login-button");
  const logoutBtn = document.getElementById("logout-button");
  if (isLoggedIn){
    loginBtn.style.display = 'none';
    logoutBtn.style.display = 'block';
  } else {
    loginBtn.style.display = 'block';
    logoutBtn.style.display = 'none';
  }
}

document
  .getElementById("add-product-form")
  .addEventListener("submit", async (e) => {
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
    location.reload();
  });

async function addToCart(productName) {
  try {
    const result = await level_6_backend.addToCart(productName);
    alert(`Added product ${productName} to cart`, result);
    console.log("success");
    location.reload();
  } catch (err) {
    alert(err);
  }
}

async function currentCart() {
  try {
    const result = await level_6_backend.currentCart();
    alert(`Current cart: ${result}`);
  } catch (err) {
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
        <div id="cart-list">
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

  document.querySelectorAll(".add-to-cart-button").forEach((button) => {
    button.addEventListener("click", (e) => {
      const productName = e.target.getAttribute("data-name");
      addToCart(productName);
      console.log(productName);
    });
  });
}

async function loadViewCart() {
  try {
    const cartItems = await level_6_backend.currentCart();
    const cartDiv = document.getElementById("cart");

    if (cartItems.length === 0) {
      cartDiv.innerHTML = `<h1>Your Cart is Empty</h1>`;
    } else {
      let cartHtml = `<h1>Your Cart</h1><div class="container"><div id="cart-items">`;
      cartItems.forEach((item) => {
        cartHtml += `
            <div class="cart-item">
              <img src="${item.image}" alt="${item.name}" />
              <p>${item.name}</p>
              <p>Price: ${item.price}</p>
              <p>Quantity: ${item.quantity}</p>
            </div>`;
      });
      cartHtml += `</div></div>`;
      cartDiv.innerHTML = cartHtml;
    }
  } catch (err) {
    console.error("Error loading cart:", err);
    alert("Error loading cart");
  }
}





document.getElementById("nav-home").addEventListener("click", loadHomePage);
document.getElementById("nav-products").addEventListener("click", loadProductPage);
document.getElementById("nav-cart").addEventListener("click", loadViewCart);

loadHomePage();
