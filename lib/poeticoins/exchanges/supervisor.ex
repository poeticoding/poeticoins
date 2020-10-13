defmodule Poeticoins.Exchanges.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      Poeticoins.Exchanges.CoinbaseClient,
      Poeticoins.Exchanges.BitstampClient
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
