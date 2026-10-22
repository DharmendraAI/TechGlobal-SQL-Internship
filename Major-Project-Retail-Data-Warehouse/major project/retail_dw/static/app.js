const $ = (id) => document.getElementById(id);
const gbp = (v) => "£" + Math.round(v).toLocaleString("en-GB");
const num = (v) => Math.round(v).toLocaleString("en-GB");
const HIER = { time: ["year", "quarter", "month"], product: ["category", "product"], geo: ["country", "category"] };
const FKEYS = ["year", "quarter", "category", "country"];
let charts = {}, path = [];   // path = drill-down values chosen so far

function qs(extra = {}) {
  const p = new URLSearchParams();
  FKEYS.forEach((k) => { const v = $("f-" + k).value; if (v) p.set(k, v); });
  Object.entries(extra).forEach(([k, v]) => p.set(k, v));
  return p.toString();
}
const get = (url, extra) => fetch(`${url}?${qs(extra)}`).then((r) => r.json());

function draw(id, type, labels, data, color, horizontal = false) {
  if (charts[id]) charts[id].destroy();
  const multi = type === "doughnut";
  charts[id] = new Chart($(id), {
    type, data: { labels, datasets: [{ data, backgroundColor: multi ? ["#0E7C86","#E8A33D","#7A3E65","#3E7CB1","#8FB339","#C8553D","#6C757D"] : color, borderColor: color, tension: .3, pointRadius: 0 }] },
    options: { indexAxis: horizontal ? "y" : "x", responsive: true, plugins: { legend: { display: multi, position: "right" } },
      scales: multi ? {} : { y: { ticks: { callback: (v) => horizontal ? v : "£" + v / 1000 + "k" } } } },
  });
}

async function loadKpis() {
  const k = await get("/api/kpis");
  $("kpis").innerHTML = [["Revenue", gbp(k.revenue)], ["Units sold", num(k.units)], ["Orders", num(k.orders)],
    ["Customers", num(k.customers)], ["Avg order value", gbp(k.avg_order)]]
    .map(([l, v]) => `<div class="kpi"><b>${v}</b><span>${l}</span></div>`).join("");
}

async function loadCharts() {
  const [trend, cat, season, prod] = await Promise.all([
    get("/api/olap", { group: "year,month" }), get("/api/olap", { group: "category" }),
    get("/api/seasonal"), get("/api/top-products", { limit: 8 })]);
  draw("c-trend", "line", trend.map((r) => `${r.year}-${String(r.month).padStart(2, "0")}`), trend.map((r) => r.revenue), "#0E7C86");
  draw("c-cat", "doughnut", cat.map((r) => r.category), cat.map((r) => r.revenue), "#fff");
  draw("c-season", "bar", season.map((r) => r.month_name), season.map((r) => r.revenue), "#E8A33D");
  draw("c-prod", "bar", prod.map((r) => r.product), prod.map((r) => r.revenue), "#7A3E65", true);
}

async function loadExplorer() {
  const levels = HIER[$("hier").value], depth = path.length, group = levels.slice(0, depth + 1);
  const extra = { group: group.join(","), rollup: $("rollup").checked ? 1 : 0 };
  path.forEach((v, i) => (extra[levels[i]] = v));          // drill-down = filter on parent levels
  const rows = await get("/api/olap", extra), last = levels[depth], canDrill = depth < levels.length - 1;
  $("crumbs").innerHTML = `<button data-i="0">All</button>` + path.map((v, i) => `<button data-i="${i + 1}">${levels[i]}: ${v}</button>`).join("");
  $("crumbs").querySelectorAll("button").forEach((b) => (b.onclick = () => { path = path.slice(0, +b.dataset.i); loadExplorer(); }));
  $("thead").innerHTML = `<th>${last}</th><th class="n">Revenue</th><th class="n">Units</th><th class="n">Orders</th>`;
  $("tbody").innerHTML = rows.map((r) => {
    const total = r[last] === null, label = total ? "Total" : r[last];
    const attrs = canDrill && !total ? `class="drill" tabindex="0" data-v="${String(label).replace(/"/g, "&quot;")}"` : total ? 'class="total"' : "";
    return `<tr ${attrs}><td>${label}</td><td class="n">${gbp(r.revenue)}</td><td class="n">${num(r.units)}</td><td class="n">${num(r.orders)}</td></tr>`;
  }).join("") || `<tr><td colspan="4">No data for these filters. Clear a filter to see results.</td></tr>`;
  $("tbody").querySelectorAll("tr.drill").forEach((tr) => {
    const go = () => { path.push(tr.dataset.v); loadExplorer(); };
    tr.onclick = go; tr.onkeydown = (e) => e.key === "Enter" && go();
  });
}

async function loadCustomers() {
  const rows = await get("/api/top-customers");
  $("cust").innerHTML = rows.map((r) => `<tr><td>${r.customer_id}</td><td>${r.country}</td><td class="n">${num(r.orders)}</td><td class="n">${gbp(r.revenue)}</td></tr>`).join("");
}

const refresh = () => { path = []; loadKpis(); loadCharts(); loadExplorer(); loadCustomers(); };

(async function init() {
  const f = await fetch("/api/filters").then((r) => r.json());
  const fill = (id, vals) => ($(id).innerHTML = `<option value="">All</option>` + vals.map((v) => `<option>${v}</option>`).join(""));
  fill("f-year", f.year); fill("f-category", f.category); fill("f-country", f.country);
  FKEYS.forEach((k) => ($("f-" + k).onchange = refresh));
  $("hier").onchange = () => { path = []; loadExplorer(); };
  $("rollup").onchange = loadExplorer;
  $("reset").onclick = () => { FKEYS.forEach((k) => ($("f-" + k).value = "")); refresh(); };
  refresh();
})();
