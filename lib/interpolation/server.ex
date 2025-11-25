defmodule Interpolation.Server do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    state = %{
      points: [],
      algorithms: init_algorithms(opts),
      step: opts[:step] || 0.1,
      newton_n: opts[:newton] || 3
    }
    {:ok, state}
  end

  defp init_algorithms(opts) do
    algorithms = []
    algorithms = if opts[:linear], do: [:linear | algorithms], else: algorithms
    algorithms = if opts[:newton], do: [:newton | algorithms], else: algorithms
    algorithms
  end

  def handle_cast({:add_point, point}, state) do
    new_points = [point | state.points] |> Enum.sort()

    results =
      state.algorithms
      |> Enum.flat_map(&calculate_points(&1, new_points, state))

    Interpolation.Output.print_results(results)
    {:noreply, %{state | points: new_points}}
  end

  def handle_cast(:eof, state) do
    {:stop, :normal, state}
  end

  defp calculate_points(:linear, points, state) do
    if length(points) >= 2 do
      [{min_x, _} | _] = points
      [{max_x, _} | _] = Enum.reverse(points)

      min_x
      |> Stream.iterate(&(&1 + state.step))
      |> Stream.take_while(&(&1 <= max_x))
      |> Enum.flat_map(fn x ->
        case Interpolation.Linear.interpolate(x, points) do
          {:ok, y} -> [{"linear", x, y}]
          :error -> []
        end
      end)
    else
      []
    end
  end

  defp calculate_points(:newton, points, state) do
    if length(points) >= state.newton_n do
      newton_points = Enum.take(points, -state.newton_n) |> Enum.sort()
      [{min_x, _} | _] = newton_points
      [{max_x, _} | _] = Enum.reverse(newton_points)

      min_x
      |> Stream.iterate(&(&1 + state.step))
      |> Stream.take_while(&(&1 <= max_x))
      |> Enum.flat_map(fn x ->
        case Interpolation.Newton.interpolate(x, newton_points, state.newton_n) do
          {:ok, y} -> [{"newton", x, y}]
          :error -> []
        end
      end)
    else
      []
    end
  end
end
