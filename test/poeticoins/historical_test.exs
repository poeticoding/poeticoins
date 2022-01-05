defmodule Poeticoins.HistoricalTest do
  use ExUnit.Case, async: false
  alias Poeticoins.{Historical, Exchanges, Product, Trade}

  describe "get_last_trade/2" do
    test "gets the most recent trade for a product" do
      historical_pid = start_fresh_historical_with_all_products()

      product = Product.new("coinbase", "BTC-USD")
      assert nil == Historical.get_last_trade(historical_pid, product)

      # broadcasting the trade
      trade = build_valid_trade(product)
      broadcast_trade(trade)

      assert trade == Historical.get_last_trade(historical_pid, product)

      new_trade = build_valid_trade(product)
      assert :gt == DateTime.compare(new_trade.traded_at, trade.traded_at)

      broadcast_trade(new_trade)
      assert new_trade == Historical.get_last_trade(historical_pid, product)
    end
  end

  describe "get_last_trades/2" do
    test "given a list of products, returns a list of most recent trades" do
      historical_pid = start_historical_with_trades_for_all_products()

      products =
        Exchanges.available_products()
        |> Enum.shuffle()

      assert MapSet.new(products) ==
               historical_pid
               |> Historical.get_last_trades(products)
               |> Enum.map(fn %Trade{product: p} -> p end)
               |> MapSet.new()
    end

    test "filtered list of trade is returned" do
      historical_pid = start_historical_with_trades_for_all_products()

      products = [
        Product.new("coinbase", "BTC-USD"),
        Product.new("coinbase", "invalid_pair"),
        Product.new("bitstamp", "btcusd")
      ]

      assert MapSet.new([Product.new("coinbase", "BTC-USD"), Product.new("bitstamp", "btcusd")]) ==
              historical_pid
               |> Historical.get_last_trades(products)
               |> Enum.map(fn %Trade{product: p} -> p end)
               |> MapSet.new()
    end
  end

  test "keeps track of the trades for only the :products passed when started" do
    historical_pid = start_fresh_historical_with_all_coinbase_products()

    coinbase_product = coinbase_btc_usd_product()

    # bitstamp trades aren't received by the historical that follows only coinbase trades
    bitstamp_product = bitstamp_btc_usd_product()
    assert nil == Historical.get_last_trade(historical_pid, bitstamp_product)

    bitstamp_product
    |> build_valid_trade()
    |> broadcast_trade()

    assert nil == Historical.get_last_trade(historical_pid, bitstamp_product)

    # broadcasting a coinbase trade, should be received
    assert nil == Historical.get_last_trade(historical_pid, coinbase_product)

    coinbase_trade = build_valid_trade(coinbase_product)
    broadcast_trade(coinbase_trade)
    assert coinbase_trade == Historical.get_last_trade(historical_pid, coinbase_product)
  end

  defp all_products, do: Exchanges.available_products()

  defp broadcast_trade(trade) do
    Exchanges.broadcast(trade)
    # wait 50ms so that the historical can get and process the message
    # Warning! In general it's better to avoid sleeps in tests!
    # sleeps tend to make tests brittle!
    Process.sleep(50)
  end

  defp coinbase_btc_usd_product, do: Product.new("coinbase", "BTC-USD")
  defp bitstamp_btc_usd_product, do: Product.new("bitstamp", "btcusd")

  defp all_coinbase_products do
    Exchanges.available_products()
    |> Enum.filter(&(&1.exchange_name == "coinbase"))
  end

  defp build_valid_trade(product) do
    %Trade{
      product: product,
      traded_at: DateTime.utc_now(),
      price: "10000.00",
      volume: "0.10000"
    }
  end

  defp start_fresh_historical_with_all_products() do
    start_supervised!({Historical, products: all_products()})
  end

  defp start_fresh_historical_with_all_coinbase_products() do
    start_supervised!({Historical, products: all_coinbase_products()})
  end

  defp start_historical_with_trades_for_all_products() do
    products = all_products()
    pid = start_supervised!({Historical, products: all_products()})
    Enum.each(products, &send(pid, {:new_trade, build_valid_trade(&1)}))
    # wait 50ms so that the historical can get and process the message
    # Warning! In general it's better to avoid sleeps in tests!
    # sleeps tend to make tests brittle!
    Process.sleep(50)

    pid
  end
end
