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

const revealItems = document.querySelectorAll(".feature-card, .env-tile, .platform-card, .faq-list details");
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

/* ---------- Environment gallery lightbox ----------
   Click a world tile to open it full-width, then navigate with scroll/swipe,
   the arrow buttons, or the keyboard. Built as a scroll-snapping track so the
   same gesture works on desktop (wheel / trackpad) and mobile (swipe). */
const envTiles = Array.from(document.querySelectorAll(".env-tile"));
if (envTiles.length) {
  const esc = (s) => s.replace(/"/g, "&quot;");
  const slides = envTiles.map((tile) => {
    const img = tile.querySelector("img");
    const source = img.currentSrc || img.src;
    return {
      full: source.replace("/env/", "/env-full/"),
      alt: img.alt,
      name: tile.querySelector(".env-name")?.textContent ?? "",
      tag: tile.querySelector(".env-tag")?.textContent ?? "",
      accent: tile.style.getPropertyValue("--accent").trim() || "#22e5ff",
    };
  });
  const pad2 = (n) => String(n).padStart(2, "0");

  const lb = document.createElement("div");
  lb.className = "lightbox";
  lb.setAttribute("role", "dialog");
  lb.setAttribute("aria-modal", "true");
  lb.setAttribute("aria-label", "Environment gallery");
  lb.innerHTML = `
    <button class="lb-close" type="button" aria-label="Close gallery">&times;</button>
    <button class="lb-nav lb-prev" type="button" aria-label="Previous world">&lsaquo;</button>
    <button class="lb-nav lb-next" type="button" aria-label="Next world">&rsaquo;</button>
    <div class="lb-track">
      ${slides
        .map(
          (s) => `<div class="lb-slide"><figure style="--accent:${s.accent}">
            <img src="${s.full.replace("/env/", "/env-full/")}" alt="${esc(s.alt)}" />
            <figcaption><span class="lb-name">${s.name}</span><span class="lb-tag">${s.tag}</span></figcaption>
          </figure></div>`,
        )
        .join("")}
    </div>
    <div class="lb-counter"><span class="lb-index">01</span> <i>/</i> ${pad2(slides.length)}</div>`;
  document.body.appendChild(lb);

  const track = lb.querySelector(".lb-track");
  const indexLabel = lb.querySelector(".lb-index");
  const prefersReduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  let current = 0;
  let wheelLock = false;

  const updateLabel = () => {
    indexLabel.textContent = pad2(current + 1);
  };
  const goTo = (i, smooth = true) => {
    current = Math.max(0, Math.min(slides.length - 1, i));
    track.scrollTo({ left: current * track.clientWidth, behavior: smooth && !prefersReduced ? "smooth" : "auto" });
    updateLabel();
  };
  const onKey = (e) => {
    if (e.key === "Escape") closeLb();
    else if (e.key === "ArrowRight") goTo(current + 1);
    else if (e.key === "ArrowLeft") goTo(current - 1);
  };
  const openLb = (i) => {
    lb.classList.add("is-open");
    document.body.style.overflow = "hidden";
    requestAnimationFrame(() => goTo(i, false));
    lb.querySelector(".lb-close").focus();
    document.addEventListener("keydown", onKey);
  };
  const closeLb = () => {
    lb.classList.remove("is-open");
    document.body.style.overflow = "";
    document.removeEventListener("keydown", onKey);
  };

  envTiles.forEach((tile, i) => {
    tile.classList.add("is-interactive");
    tile.setAttribute("role", "button");
    tile.setAttribute("tabindex", "0");
    tile.setAttribute("aria-label", `View ${slides[i].name} full screen`);
    tile.addEventListener("click", () => openLb(i));
    tile.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        openLb(i);
      }
    });
  });

  lb.querySelector(".lb-close").addEventListener("click", closeLb);
  lb.querySelector(".lb-prev").addEventListener("click", () => goTo(current - 1));
  lb.querySelector(".lb-next").addEventListener("click", () => goTo(current + 1));
  track.addEventListener("click", (e) => {
    if (!e.target.closest("img") && !e.target.closest("figcaption")) closeLb();
  });

  let scrollRaf;
  track.addEventListener("scroll", () => {
    cancelAnimationFrame(scrollRaf);
    scrollRaf = requestAnimationFrame(() => {
      const i = Math.round(track.scrollLeft / track.clientWidth);
      if (i !== current) {
        current = i;
        updateLabel();
      }
    });
  });

  // vertical wheel maps to one slide step (trackpad horizontal scroll works natively)
  track.addEventListener(
    "wheel",
    (e) => {
      const delta = Math.abs(e.deltaY) >= Math.abs(e.deltaX) ? e.deltaY : e.deltaX;
      if (Math.abs(delta) < 6) return;
      e.preventDefault();
      if (wheelLock) return;
      wheelLock = true;
      goTo(current + (delta > 0 ? 1 : -1));
      setTimeout(() => {
        wheelLock = false;
      }, 420);
    },
    { passive: false },
  );

  window.addEventListener("resize", () => goTo(current, false));
}
