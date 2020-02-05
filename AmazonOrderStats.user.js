// ==UserScript==
// @name         AmazonOrderStats
// @namespace    https://amazon.de/
// @version      0.1
// @description  Statistics for your amazon orders
// @author       Flowm
// @match        https://www.amazon.de/gp/your-account/order-history*
// @require      https://cdn.jsdelivr.net/npm/moment@2.24.0/moment.min.js
// @require      https://cdn.jsdelivr.net/npm/moment@2.24.0/locale/de.min.js
// @grant        none
// ==/UserScript==

function getOrdersFromPage() {
    moment.locale('de');
    const orders = [...document.querySelectorAll("div#ordersContainer div.order")].map((order) => {
        const details = order.querySelector("div.order-info");
        //console.log(details);
        let [date, amount] = details.querySelectorAll("div.a-col-left span.a-color-secondary.value");
        date = moment(date.innerText, "D. MMMM YYYY").format("YYYY-MM-DD");
        amount = amount.innerText.replace("EUR ", "").replace(",", ".");
        //console.log("ORDER", date, amount)
        return {date, amount};
    });
    return orders
}

function mergeOrders() {
    const local = localStorage.getItem("orders");
    const oldOrders = local ? JSON.parse(local) : [];
    // console.log("OLD", oldOrders);

    const newOrders = getOrdersFromPage();
    // console.log("NEW", newOrders);

    const uniqueOrders = [];
    [...oldOrders, ...newOrders].forEach((order) => {
        if (!uniqueOrders.some(u => u.date === order.date && u.amount === order.amount)) {
            uniqueOrders.push(order);
        }
    });

    const sortedOrders = uniqueOrders.sort((a, b) => a.date.localeCompare(b.date));

    const orders = sortedOrders;
    // console.log("ALL", orders);
    localStorage.setItem("orders", JSON.stringify(orders));
    return orders;
}

function addButton(text, onclick, cssObj) {
    cssObj = cssObj || {position: 'absolute', bottom: '7%', left:'4%', 'z-index': 10}
    let button = document.createElement('button')
    document.body.appendChild(button)
    button.innerHTML = text
    button.onclick = onclick
    Object.keys(cssObj).forEach(style => {button.style[style] = cssObj[style]})
    return button
}

function exportCSV(data) {
    const keys = data.map((ele) => Object.keys(ele)).flat().filter((e, i, arr) => arr.indexOf(e) === i);
    let csv = `${keys.join(",")}\n`;
    data.forEach((ele) => {
        csv += `${keys.map((key) => (key in ele ? ele[key] : "")).join(",")}\n`;
    });
    const element = document.createElement("a");
    element.href = `data:text/csv;charset=utf-8,${encodeURI(csv)}`;
    element.target = "_blank";
    element.download = "orders.csv";
    element.click();
}

(function() {
    'use strict';
    const orders = mergeOrders();
    console.log(orders);
    addButton("Export", () => { exportCSV(orders) }, {position: 'absolute', bottom: '10%', left:'2%', 'z-index': 10});
    addButton("Clear", () => { localStorage.clear() }, {position: 'absolute', bottom: '5%', left:'2%', 'z-index': 10});
})();