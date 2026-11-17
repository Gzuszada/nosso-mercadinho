{{flutter_js}}
{{flutter_build_config}}

const showWebCompatibilityError = (message) => {
  const container = document.createElement("div");
  container.setAttribute("role", "alert");
  container.style.cssText = [
    "box-sizing:border-box",
    "max-width:36rem",
    "margin:12vh auto",
    "padding:1.5rem",
    "font:1rem/1.5 system-ui,sans-serif",
    "color:#1f2937",
    "background:#fff",
    "border:1px solid #d1d5db",
    "border-radius:.75rem",
    "text-align:center",
  ].join(";");
  container.textContent = message;
  document.body.appendChild(container);
};

window.addEventListener("error", (event) => {
  showWebCompatibilityError(
    "Não foi possível iniciar o app neste navegador. Atualize o Safari e tente novamente. Se o problema continuar, abra o mercado pelo navegador mais atualizado do celular.",
  );
  console.error(event.error || event.message);
});

_flutter.loader.load();