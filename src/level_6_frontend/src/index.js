import { level_6_backend } from "../../declarations/level_6_backend";

document.getElementById("add-product-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const name = document.getElementById("product-name").value;
  const price = Number(document.getElementById("product-price").value);
  const description = document.getElementById("product-description").value;
  const image = document.getElementById("product-image").value;

  const result = await level_6_backend.addProduct(name, price, description, image, false);
  alert(`Added product ${result.name} with id ${result.name}`);
});
