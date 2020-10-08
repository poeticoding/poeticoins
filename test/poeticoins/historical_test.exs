defmodule Poeticoins.HistoricalTest do
  use ExUnit.Case, async: true
  alias Poeticoins.{Historical, Exchanges, Product, Trade}

  describe "get_last_trade/2" do
    setup do
      {:ok, pid} = Historical.start_link(products: all_products())
      [historical: pid]
    end
    test "returns the most recent trade", %{historical: historical} do
      product = Product.new("coinbase", "BTC-USD")
      assert nil == Historical.get_last_trade(historical, product)

      #broadcasting the trade
      trade = build_valid_trade(product)
      broadcast_trade(trade)
      assert trade == Historical.get_last_trade(historical, product)
    end
  end

  defp all_products, do: Exchanges.available_products()
  defp broadcast_trade(trade), do: Exchanges.broadcast(trade)
  defp build_valid_trade(product) do
    %Trade{
      product: product,
      traded_at: DateTime.utc_now(),
      price: "10000.00",
      volume: "0.10000"
    }
  end
end
