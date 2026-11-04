document.addEventListener("turbo:before-stream-render", (event) => {
  if (!event.target.dataset.discountsVersion) return;

  const render = event.detail.render;
  event.detail.render = (stream) => {
    const target = stream.targetElements[0];
    const table = target?.closest("[data-discounts-order]");
    if (!table || table.dataset.discountsOrder !== stream.dataset.discountsOrder) return;
    const version = stream.dataset.discountsVersion;
    const currentVersion = target.dataset.discountsVersion ?? table.dataset.discountsVersion;
    if (version <= currentVersion) return;

    render(stream);
    target.dataset.discountsVersion = stream.dataset.discountsVersion;
  };
});
