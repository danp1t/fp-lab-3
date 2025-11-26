defmodule Interpolation.Server do
  @moduledoc """
  GenServer для управления состоянием интерполяции и координации вычислений.
  Обрабатывает добавление точек данных и запуск алгоритмов интерполяции.
  """

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
      calculate_linear_points(points, state.step)
    else
      []
    end
  end

  defp calculate_points(:newton, points, state) do
    if length(points) >= state.newton_n do
      calculate_newton_points(points, state.step, state.newton_n)
    else
      []
    end
  end

  defp calculate_linear_points(points, step) do
    [{min_x, _} | _] = points
    [{max_x, _} | _] = Enum.reverse(points)

    min_x
    |> Stream.iterate(&(&1 + step))
    |> Stream.take_while(&(&1 <= max_x))
    |> Stream.flat_map(&interpolate_linear(&1, points))
    |> Enum.to_list()
  end

  defp interpolate_linear(x, points) do
    case Interpolation.Linear.interpolate(x, points) do
      {:ok, y} -> [{"linear", x, y}]
      :error -> []
    end
  end

  defp calculate_newton_points(points, step, newton_n) do
    newton_points = Enum.take(points, -newton_n) |> Enum.sort()
    [{min_x, _} | _] = newton_points
    [{max_x, _} | _] = Enum.reverse(newton_points)

    min_x
    |> Stream.iterate(&(&1 + step))
    |> Stream.take_while(&(&1 <= max_x))
    |> Stream.flat_map(&interpolate_newton(&1, newton_points, newton_n))
    |> Enum.to_list()
  end

  defp interpolate_newton(x, newton_points, newton_n) do
    case Interpolation.Newton.interpolate(x, newton_points, newton_n) do
      {:ok, y} -> [{"newton", x, y}]
      :error -> []
    end
  end
end
