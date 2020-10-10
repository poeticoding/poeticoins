defmodule Poeticoins.HistoricalTest do
  use ExUnit.Case, async: true
  alias Poeticoins.{Historical, Exchanges, Product, Trade}


  setup :start_fresh_historical_with_all_products
  setup :start_fresh_historical_with_all_coinbase_products
  setup :start_historical_with_trades_for_all_products

  describe "get_last_trade/2" do
    test "gets the most recent trade for a product", %{hist_all: historical} do
      product = Product.new("coinbase", "BTC-USD")
      assert nil == Historical.get_last_trade(historical, product)

      #broadcasting the trade
      trade = build_valid_trade(product)
      broadcast_trade(trade)
      assert trade == Historical.get_last_trade(historical, product)

      new_trade = build_valid_trade(product)
      assert :gt == DateTime.compare(new_trade.traded_at, trade.traded_at)

      broadcast_trade(new_trade)
      assert new_trade == Historical.get_last_trade(historical, product)

    end
  end

  describe "get_last_trades/2" do
    test "given a list of products, returns a list of most recent trades", %{hist_with_trades: historical} do
      products =
        Exchanges.available_products()
        |> Enum.shuffle()

      assert products ==
        historical
        |> Historical.get_last_trades(products)
        |> Enum.map(fn %Trade{product: p} -> p end)
    end

    test "nil in the returned list when the Historical doesn't have a trade for product", %{hist_with_trades: historical} do
      products = [
        Product.new("coinbase", "BTC-USD"),
        Product.new("coinbase", "invalid_pair"),
        Product.new("bitstamp", "btcusd")
      ]

      assert [%Trade{}, nil, %Trade{}] = Historical.get_last_trades(historical, products)
    end
  end

  test "keeps track of the trades for only the :products passed when started", %{hist_coinbase: hist_coinbase} do
    coinbase_product = coinbase_btc_usd_product()

    # bitstamp trades aren't received by the historical that follows only coinbase trades
    bitstamp_product = bitstamp_btc_usd_product()
    assert nil == Historical.get_last_trade(hist_coinbase, bitstamp_product)

    bitstamp_product
    |> build_valid_trade()
    |> broadcast_trade()

    assert nil == Historical.get_last_trade(hist_coinbase, bitstamp_product)


    # broadcasting a coinbase trade, should be received
    assert nil == Historical.get_last_trade(hist_coinbase, coinbase_product)

    coinbase_trade = build_valid_trade(coinbase_product)
    broadcast_trade(coinbase_trade)
    assert coinbase_trade == Historical.get_last_trade(hist_coinbase, coinbase_product)

  end


  defp all_products, do: Exchanges.available_products()
  defp broadcast_trade(trade), do: Exchanges.broadcast(trade)
  defp coinbase_btc_usd_product, do: Product.new("coinbase", "BTC-USD")
  defp bitstamp_btc_usd_product, do: Product.new("bitstamp", "btcusd")
  defp all_coinbase_products do
    Exchanges.available_products()
    |> Enum.filter(& &1.exchange_name == "coinbase")
  end
  defp build_valid_trade(product) do
    %Trade{
      product: product,
      traded_at: DateTime.utc_now(),
      price: "10000.00",
      volume: "0.10000"
    }
  end


  defp start_fresh_historical_with_all_products(_context) do
    {:ok, hist_all} = Historical.start_link(products: all_products())
    [hist_all: hist_all]
  end

  defp start_fresh_historical_with_all_coinbase_products(_context) do
    {:ok, hist_coinbase} = Historical.start_link(products: all_coinbase_products())
    [hist_coinbase: hist_coinbase]
  end

  defp start_historical_with_trades_for_all_products(_context) do
    products = all_products()
    {:ok, hist} = Historical.start_link(products: products)
    Enum.each(products, & send(hist, {:new_trade, build_valid_trade(&1)}))
    [hist_with_trades: hist]
  end
end
