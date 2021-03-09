//assets/js/chart.js
import _css from 'uplot/dist/uPlot.min.css'
import uPlot from "uplot"

let plotOpts = {
  width: 200, height: 80, class: "chart-container",
  cursor: { show: false }, select: { show: false }, legend: { show: false, },
  scales: {
  },
  axes: [
    {
      show: false,
    },
    {
      show: false,
    }
  ],
  series: [
    {},
    {
      size: 0,
      width: 2,
      stroke: "white",
      fill: "rgb(45,85,150)",
    },
  ],
};


let ChartHook = {
  mounted() {
    let productId = this.el.dataset.productId,
      event = `new-trade:${productId}`,
      self = this;

    this.trades = [];
    this.plot = new uPlot(plotOpts, [[], []], this.el);
    this.handleEvent(event, (payload) => self.handleNewTrade(payload));
  },
  handleNewTrade(trade) {
    let price = parseFloat(trade.price),
      timestamp = trade.traded_at;

    this.trades.push({
      timestamp: timestamp, price: price
    });

    if (this.trades.length > 20) {
      this.trades.splice(0, 1);
    }

    this.updateChart();
  },


  updateChart() {
    let x = this.trades.map(t => t.timestamp);
    let y = this.trades.map(t => t.price);
    this.plot.setData([x, y]);
  }
}

export { ChartHook }
