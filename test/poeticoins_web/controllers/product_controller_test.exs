defmodule PoeticoinsWeb.ProductControllerTest do
  use PoeticoinsWeb.ConnCase
  alias Poeticoins.{Historical, Trade, Product}

  # setup do
  #   Historical.clear()
  #   :ok
  # end

  # describe "index" do
  #   test "empty trades table", %{conn: conn} do
  #     conn = get(conn, Routes.product_path(conn, :index))
  #     assert html_response(conn, 200) =~ "<table>"
  #     refute html_response(conn, 200) =~ "<tr>"
  #   end

  #   test "renders historical trades in a table", %{conn: conn} do
  #     trade = build_trade_and_broadcast()
  #     conn = get(conn, Routes.product_path(conn, :index))

  #     assert html_response(conn, 200) =~ "<td>#{trade.product.exchange_name}</td>"
  #     assert html_response(conn, 200) =~ "<td>#{trade.product.currency_pair}</td>"
  #     assert html_response(conn, 200) =~ "<td>#{trade.price}</td>"
  #     assert html_response(conn, 200) =~ "<td>#{trade.volume}</td>"
  #     assert html_response(conn, 200) =~ "<td>#{trade.traded_at}</td>"
  #   end
  # end

  defp valid_trade() do
    %Trade{
      product: Product.new("coinbase", "BTC-USD"),
      traded_at: DateTime.utc_now(),
      price: "10000.00",
      volume: "0.10000"
    }
  end

  defp build_trade_and_broadcast() do
    trade = valid_trade()
    Poeticoins.Exchanges.broadcast(trade)
    trade
  end
end
