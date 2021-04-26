
import Highcharts from 'highcharts/highstock';
import darkTheme from 'highcharts/themes/dark-unica'
darkTheme(Highcharts)


let StockChartHook = {
  mounted() {
    this.trades = [];
    this.chart = Highcharts.stockChart('stockchart-container', {
      title: {
        text: this.el.dataset.productName
      },

      series: [{
        name: this.el.dataset.productName,
        data: [],
        tooltip: {
          valueDecimals: 2
        }
      },
      {
        type: 'column',
        name: 'Volume',
        data: [],
        yAxis: 1
      }],


      yAxis: [{
        labels: {
          align: 'right',
          x: -3
        },
        title: {
          text: 'Price'
        },
        height: '60%',
        lineWidth: 2,
        resize: {
          enabled: true
        }
      }, {
        labels: {
          align: 'right',
          x: -3
        },
        title: {
          text: 'Volume'
        },
        top: '65%',
        height: '35%',
        offset: 0,
        lineWidth: 2
      }]
    });
  },
  updated() {
    if (this.hasValidTrade()) {
      let trade = this.getTradeFromDataset()
      this.chart.series[0].addPoint([trade.timestamp, trade.price]);
      this.chart.series[1].addPoint([trade.timestamp, trade.volume]);
    }
  },
  getTradeFromDataset() {
    return {
      timestamp: parseInt(this.el.dataset.tradeTimestamp),
      price: parseFloat(this.el.dataset.tradePrice),
      volume: parseFloat(this.el.dataset.tradeVolume),
    }
  },
  hasValidTrade() {
    return this.el.dataset.tradeTimestamp != undefined
  }
};

export { StockChartHook }