import { readFileSync } from "node:fs";
import { runInNewContext } from "node:vm";
import { test } from "node:test";
import assert from "node:assert/strict";

const source = readFileSync(new URL("../../app/javascript/discount_streams.js", import.meta.url), "utf8");
const timestamp = (fraction) => `2026-11-04T15:00:00.${fraction.padStart(6, "0")}Z`;

function page(order = "first", version = "8") {
  const document = new EventTarget();
  const table = { dataset: { discountsOrder: order, discountsVersion: timestamp(version) } };
  const targets = Object.fromEntries(["total", "saving", "line"].map(id => [id, {
    dataset: {}, textContent: "$60.00", closest: () => table
  }]));
  runInNewContext(source, { document });
  return {
    targets,
    table,
    receive(target, version, text, order = table.dataset.discountsOrder) {
      const stream = { dataset: { discountsVersion: version && timestamp(version), discountsOrder: order }, targetElements: [targets[target]] };
      const event = new Event("turbo:before-stream-render");
      Object.defineProperty(event, "target", { value: stream });
      event.detail = { render: () => { if (targets[target]) targets[target].textContent = text; } };
      document.dispatchEvent(event);
      return () => event.detail.render(stream);
    }
  };
}

test("a late intermediate result cannot overwrite any field of the final discount result", () => {
  const browser = page();
  for (const target of ["total", "saving", "line"]) {
    browser.receive(target, "10", target === "saving" ? "$20.00" : "$60.00")();
    browser.receive(target, "9", target === "saving" ? "$0.00" : "$80.00")();
  }
  assert.equal(browser.targets.total.textContent, "$60.00");
  assert.equal(browser.targets.saving.textContent, "$20.00");
  assert.equal(browser.targets.line.textContent, "$60.00");
});

test("fresh HTML rejects older messages before any live update", () => {
  const browser = page();
  browser.receive("total", "7", "$80.00")();
  assert.equal(browser.targets.total.textContent, "$60.00");
});

test("navigation scopes product targets and their versions to the current order", () => {
  const browser = page("second", "1");
  browser.receive("line", "100", "$80.00", "first")();
  assert.equal(browser.targets.line.textContent, "$60.00");
  browser.receive("line", "2", "$54.00", "second")();
  assert.equal(browser.targets.line.textContent, "$54.00");
});

test("freshness is checked when Turbo renders, not when it receives the message", () => {
  const browser = page();
  const older = browser.receive("total", "9", "$80.00");
  const newer = browser.receive("total", "10", "$54.00");
  newer();
  older();
  assert.equal(browser.targets.total.textContent, "$54.00");
});

test("equal timestamps keep the first rendered value without blocking other targets", () => {
  const browser = page();
  browser.receive("total", "9", "$54.00")();
  browser.receive("total", "9", "$80.00")();
  browser.receive("saving", "9", "$26.00")();
  assert.equal(browser.targets.total.textContent, "$54.00");
  assert.equal(browser.targets.saving.textContent, "$26.00");
});

test("timestamps within the same millisecond retain their microsecond precision", () => {
  const browser = page("first", "123456");
  browser.receive("total", "123457", "$54.00")();
  browser.receive("total", "123456", "$80.00")();
  assert.equal(browser.targets.total.textContent, "$54.00");
});

test("missing targets and unrelated unversioned updates retain normal Turbo behavior", () => {
  const browser = page();
  browser.receive("total", undefined, "$40.00")();
  assert.equal(browser.targets.total.textContent, "$40.00");
  assert.doesNotThrow(browser.receive("missing", "9", "$40.00"));
});
