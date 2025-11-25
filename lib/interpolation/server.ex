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
      newton_n: opts[:newton] || 3,
      last_x: %{},
      first_processing: true
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
    new_points = insert_sorted(state.points, point)
    state = %{state | points: new_points}
    {new_state, results} = process_algorithms(state)

    Interpolation.Output.print_results(results)
    {:noreply, new_state}
  end

  def handle_cast(:eof, state) do
    {final_state, results} = process_eof(state)
    Interpolation.Output.print_results(results)
    {:stop, :normal, final_state}
  end

  defp insert_sorted(points, {x, _y} = point) do
    {less, greater} = Enum.split_while(points, fn {px, _py} -> px < x end)
    less ++ [point] ++ greater
  end

  defp process_algorithms(state) do
    Enum.reduce(state.algorithms, {state, []}, fn algorithm, {current_state, all_results} ->
      {new_state, results} = process_algorithm(current_state, algorithm)
      {new_state, all_results ++ results}
    end)
  end

  defp process_algorithm(state, algorithm) do
    case algorithm do
      :linear -> process_linear(state)
      :newton -> process_newton(state)
    end
  end

  defp process_linear(state) do
    if length(state.points) < 2 do
      {state, []}
    else
      {min_x, _} = List.first(state.points)
      {max_x, _} = List.last(state.points)

      last_x = Map.get(state.last_x, :linear, min_x)
      start_x = if state.first_processing, do: min_x, else: last_x + state.step

      {points, new_last_x} = generate_linear_points(state.points, start_x, max_x, state.step, [])

      state = %{state |
        last_x: Map.put(state.last_x, :linear, new_last_x),
        first_processing: false
      }
      {state, points}
    end
  end

  defp process_newton(state) do
    if length(state.points) < state.newton_n do
      {state, []}
    else
      newton_points = Enum.take(state.points, -state.newton_n)
      {min_x, _} = List.first(newton_points)
      {max_x, _} = List.last(newton_points)

      last_x = Map.get(state.last_x, :newton, min_x)
      start_x = if state.first_processing, do: min_x, else: last_x + state.step

      {points, new_last_x} = generate_newton_points(newton_points, start_x, max_x, state.step, state.newton_n, [])

      state = %{state |
        last_x: Map.put(state.last_x, :newton, new_last_x),
        first_processing: false
      }
      {state, points}
    end
  end

  defp process_eof(state) do
    Enum.reduce(state.algorithms, {state, []}, fn algorithm, {current_state, all_results} ->
      {new_state, results} = process_algorithm_eof(current_state, algorithm)
      {new_state, all_results ++ results}
    end)
  end

  defp process_algorithm_eof(state, algorithm) do
    case algorithm do
      :linear -> process_linear_eof(state)
      :newton -> process_newton_eof(state)
    end
  end

  defp process_linear_eof(state) do
    if length(state.points) < 2 do
      {state, []}
    else
      {min_x, _} = List.first(state.points)
      {max_x, _} = List.last(state.points)

      last_x = Map.get(state.last_x, :linear, min_x)
      start_x = last_x + state.step

      {points, _} = generate_linear_points(state.points, start_x, max_x, state.step, [])
      {state, points}
    end
  end

  defp process_newton_eof(state) do
    if length(state.points) < state.newton_n do
      {state, []}
    else
      newton_points = Enum.take(state.points, -state.newton_n)
      {min_x, _} = List.first(newton_points)
      {max_x, _} = List.last(newton_points)

      last_x = Map.get(state.last_x, :newton, min_x)
      start_x = last_x + state.step

      {points, _} = generate_newton_points(newton_points, start_x, max_x, state.step, state.newton_n, [])
      {state, points}
    end
  end

  defp generate_linear_points(points, current_x, max_x, step, acc) do
    if current_x <= max_x + 1.0e-10 do
      case Interpolation.Linear.interpolate(current_x, points) do
        {:ok, y} ->
          point = {"linear", current_x, y}
          generate_linear_points(points, current_x + step, max_x, step, acc ++ [point])
        :error ->
          generate_linear_points(points, current_x + step, max_x, step, acc)
      end
    else
      last_x = if acc == [], do: current_x - step, else: current_x - step
      {acc, last_x}
    end
  end

  defp generate_newton_points(points, current_x, max_x, step, n, acc) do
    if current_x <= max_x + 1.0e-10 do
      case Interpolation.Newton.interpolate(current_x, points, n) do
        {:ok, y} ->
          point = {"newton", current_x, y}
          generate_newton_points(points, current_x + step, max_x, step, n, acc ++ [point])
        :error ->
          generate_newton_points(points, current_x + step, max_x, step, n, acc)
      end
    else
      last_x = if acc == [], do: current_x - step, else: current_x - step
      {acc, last_x}
    end
  end
end
