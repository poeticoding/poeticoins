Application.stop(:poeticoins)

list = Enum.map(1..1000, & "#{&1}")
queue = :queue.from_list(list)

list_append_and_drop_fun = fn el, list ->
  list
  |> Enum.drop(1)
  |> Kernel.++([el])
end

queue_insert_and_drop_fun = fn el, q ->
  :queue.in(el, q)
  |> :queue.drop()
end

new_elements = Enum.map(1001..1101, & "#{&1}")

Benchee.run(
  %{
    "list: append 1001 and drop 1" => fn ->
      list_append_and_drop_fun.("1001", list)
    end,
    "queue: in 1001 and drop 1" => fn ->
      queue_insert_and_drop_fun.("1001", queue)
    end

    "list: hundred appends and drops" => fn ->
      Enum.reduce(new_elements, list, list_append_and_drop_fun)
    end,
    "queue: hundred appends and drops" => fn ->
      Enum.reduce(new_elements, queue, queue_insert_and_drop_fun)
    end,

    "convert a queue to a list" => fn ->
      :queue.to_list(queue)
    end

  },

  time: 10,
  memory_time: 2
)
