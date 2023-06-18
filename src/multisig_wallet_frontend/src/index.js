import { multisig_wallet_backend } from "../../declarations/multisig_wallet_backend";

document.querySelector("form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const button = e.target.querySelector("button");

  const name = document.getElementById("name").value.toString();

  button.setAttribute("disabled", true);

  // Interact with foo actor, calling the greet method
  const greeting = await multisig_wallet_backend.call_get_eth_gas_price();

  button.removeAttribute("disabled");

  document.getElementById("greeting").innerText = greeting;

  return false;
});
