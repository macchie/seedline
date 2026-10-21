import "./style.css";

const seedCode = document.querySelector("#seed-code");
const seedStatus = document.querySelector("#seed-status");
const codeAlphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";

document.querySelector("#year").textContent = new Date().getFullYear();

document.querySelector("#roll-seed").addEventListener("click", () => {
  const seed = [];
  const limit = 256 - (256 % codeAlphabet.length);
  while (seed.length < 16) {
    const bytes = crypto.getRandomValues(new Uint8Array(32));
    for (const byte of bytes) {
      if (byte < limit) seed.push(codeAlphabet[byte % codeAlphabet.length]);
      if (seed.length === 16) break;
    }
  }
  seedCode.textContent = seed.join("");
  seedStatus.textContent = "Fresh seed. Same code, same track.";
});

document.querySelector("#copy-seed").addEventListener("click", async () => {
  try {
    await navigator.clipboard.writeText(seedCode.textContent);
    seedStatus.textContent = "Seed copied. Share the circuit.";
  } catch {
    seedStatus.textContent = "Clipboard unavailable. Select the seed to copy it.";
  }
});

const navToggle = document.querySelector(".nav-toggle");
const primaryNav = document.querySelector("#primary-nav");

function closeNavigation() {
  navToggle.setAttribute("aria-expanded", "false");
  navToggle.querySelector(".sr-only").textContent = "Open navigation";
  primaryNav.classList.remove("is-open");
}

navToggle.addEventListener("click", () => {
  const isOpen = navToggle.getAttribute("aria-expanded") === "true";
  navToggle.setAttribute("aria-expanded", String(!isOpen));
  navToggle.querySelector(".sr-only").textContent = isOpen ? "Open navigation" : "Close navigation";
  primaryNav.classList.toggle("is-open", !isOpen);
});

primaryNav.querySelectorAll("a").forEach((link) => {
  link.addEventListener("click", closeNavigation);
});

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") closeNavigation();
});

const revealItems = document.querySelectorAll(".feature-card, .platform-card, .faq-list details");
if ("IntersectionObserver" in window && !window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
  const observer = new IntersectionObserver(
    (entries, currentObserver) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("is-visible");
        currentObserver.unobserve(entry.target);
      });
    },
    { threshold: 0.12 },
  );
  revealItems.forEach((item) => {
    item.classList.add("will-reveal");
    observer.observe(item);
  });
}
