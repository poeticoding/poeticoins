defmodule Poeticoins.Historical.TimeSeries do
  alias Poeticoins.Trade
  @window_size 100

  @type series :: :queue.queue(Trade)
  @type t :: %__MODULE__{
    count: integer(),
    series: series,
    max: integer()
  }

  defstruct [:count, :series, :max]


  @spec new() :: t()
  def new() do
    %__MODULE__{ count: 0, series: :queue.new(), max: @window_size}
  end

  @spec add(t, Trade.t) :: t()
  def add(%{count: count, max: max}=ts, new_trade) when count >= max do
    ts
    |> drop()
    |> add(new_trade)
  end

  def add(ts, new_trade) do
    %{ts | series: :queue.in(new_trade, ts.series), count: ts.count + 1}
  end

  @spec drop(t()) :: t()
  defp drop(ts) do
    %{ts | series: :queue.drop(ts.series), count: ts.count - 1}
  end

  @spec last(t()) :: Trade.t | nil
  def last(%{count: 0}=_ts), do: nil

  def last(ts), do: :queue.last(ts.series)

  @spec to_list(t()) :: [Trade.t()]
  def to_list(ts) do
    :queue.to_list(ts.series)
  end

end
