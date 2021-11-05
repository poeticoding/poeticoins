defmodule Poeticoins.Historical do
  use GenServer
  alias Poeticoins.{Product, Trade, Exchanges}
  alias Poeticoins.Historical.TimeSeries

  @type t() :: %__MODULE__{
          products: [Product.t()],
          series: %{ Product.t() => TimeSeries.t()}
        }

  defstruct [:products, :series]


  @spec get_last_trade(pid | atom, Product.t()) :: Trade.t() | nil
  def get_last_trade(pid \\ __MODULE__, product) do
    GenServer.call(pid, {:get_last_trade, product})
  end

  @spec get_last_trades(pid | atom, [Product.t()]) :: [Trade.t()]
  def get_last_trades(pid \\__MODULE__, products) do
    GenServer.call(pid, {:get_last_trades, products})
  end

  @spec get_trades(pid | atom, Product.t) :: [Trade.t()]
  def get_trades(pid \\__MODULE__, product) do
    GenServer.call(pid, {:get_trades, product})
  end


  # :products
  def start_link(opts) do
    {products, opts} = Keyword.pop(opts, :products, Exchanges.available_products())
    GenServer.start_link(__MODULE__, products, opts)
  end

  def init(products) do
    historical = %__MODULE__{products: products, series: %{}}
    {:ok, historical, {:continue, :subscribe}}
  end

  def handle_continue(:subscribe, historical) do
    Enum.each(historical.products, &Exchanges.subscribe/1)
    {:noreply, historical}
  end

  def handle_info({:new_trade, trade}, historical) do
    updated_historical = add_trade(historical, trade)
    {:noreply, updated_historical}
  end

  def handle_call({:get_last_trade, product}, _from, historical) do
    trade = get_timeseries(historical, product, &TimeSeries.last/1)
    {:reply, trade, historical}
  end

  def handle_call({:get_last_trades, products}, _from, historical) do
    trades =
      products
      |> Enum.map(fn product -> get_timeseries(historical, product, &TimeSeries.last/1) end)
      |> Enum.filter(& not is_nil(&1))

    {:reply, trades, historical}
  end

  def handle_call({:get_trades, product}, _from, historical) do
    trades = get_timeseries(historical, product, &TimeSeries.to_list/1)
    {:reply, trades, historical}
  end


  @spec get_timeseries(t(), Product.t, function()) :: term | nil
  defp get_timeseries(historical, product, fun) do
    historical.series
    |> Map.get(product)
    |> case do
      nil -> nil
      ts -> fun.(ts)
    end
  end


  @spec add_trade(t(), Trade.t) :: t()
  defp add_trade(%{series: series}=historical, trade) do
    updated_series =
      if Map.has_key?(series, trade.product) do
        Map.update!(series, trade.product, & TimeSeries.add(&1, trade))
      else
        ts =
          TimeSeries.new()
          |> TimeSeries.add(trade)
        Map.put(series, trade.product, ts)
      end
    %{historical | series: updated_series}
  end
end
