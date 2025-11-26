# Лабораторная работа №3
## Путинцев Данил

Цель: получить навыки работы с вводом/выводом, потоковой обработкой данных, командной строкой.

В рамках лабораторной работы вам предлагается повторно реализовать лабораторную работу по предмету "Вычислительная математика" посвящённую интерполяции (в разные годы это лабораторная работа 3 или 4) со следующими дополнениями:

- обязательно должна быть реализована линейная интерполяция (отрезками, [link](https://en.wikipedia.org/wiki/Linear_interpolation));
- настройки алгоритма интерполяции и выводимых данных должны задаваться через аргументы командной строки:
    - какие алгоритмы использовать (в том числе два сразу);
    - частота дискретизации результирующих данных;
    - и т.п.;
- входные данные должны задаваться в текстовом формате на подобии ".csv" (к примеру `x;y\n` или `x\ty\n`) и подаваться на стандартный ввод, входные данные должны быть отсортированы по возрастанию x;
- выходные данные должны подаваться на стандартный вывод;
- программа должна работать в потоковом режиме (пример -- `cat | grep 11`), это значит, что при запуске программы она должна ожидать получения данных на стандартный ввод, и, по мере получения достаточного количества данных, должна выводить рассчитанные точки в стандартный вывод;

Приложение должно быть организовано следующим образом:

```text
    +---------------------------+
    | обработка входного потока |
    +---------------------------+
            |
            | поток / список / последовательность точек
            v
    +-----------------------+      +------------------------------+
    | алгоритм интерполяции |<-----| генератор точек, для которых |
    +-----------------------+      | необходимо вычислить         |
            |                      | промежуточные значения       |
            |                      +------------------------------+
            |
            | поток / список / последовательность рассчитанных точек
            v
    +------------------------+
    | печать выходных данных |
    +------------------------+
```

Потоковый режим для алгоритмов, работающих с группой точек должен работать следующим образом:

```text
o o o o o o . . x x x
  x x x . . o . . x x x
    x x x . . o . . x x x
      x x x . . o . . x x x
        x x x . . o . . x x x
          x x x . . o . . x x x
            x x x . . o o o o o o EOF
```

где:

- каждая строка -- окно данных, на основании которых производится расчёт алгоритма;
- строки сменяются по мере поступления в систему новых данных (старые данные удаляются из окна, новые -- добавляются);
- `o` -- рассчитанные данные, можно видеть:
    - большинство окон используется для расчёта всего одной точки, так как именно в "центре" результат наиболее точен;
    - первое и последнее окно используются для расчёта большого количества точек, так лучших данных для расчёта у нас не будет.
- `.` -- точки, задействованные в рассчете значения `o`.
- `x` -- точки, расчёт которых для "окон" не требуется.

### Пример вычислений #1. Линейная интерполяция
```bash
./interpolation -l -s 0.7
0 0
1 1
linear: 0 0
linear: 0.7 0.7
2 2
linear: 0 0
linear: 0.7 0.7
linear: 1.4 1.4
3 3
linear: 0 0
linear: 0.7 0.7
linear: 1.4 1.4
linear: 2.0999999999999996 2.0999999999999996
linear: 2.8 2.8
```

### Пример вычислений #2. Метод Ньютона
```bash
./interpolation -n 5 -s 0.5
0 0
1 1
2 2
3 3
4 4
newton: 0 0
newton: 0.5 0.5
newton: 1 1
newton: 1.5 1.5
newton: 2 2
newton: 2.5 2.5
newton: 3 3
newton: 3.5 3.5
newton: 4 4
5 5
newton: 1 1
newton: 1.5 1.5
newton: 2 2
newton: 2.5 2.5
newton: 3 3
newton: 3.5 3.5
newton: 4 4
newton: 4.5 4.5
newton: 5 5
7 7
newton: 2 2
newton: 2.5 2.5
newton: 3 3
newton: 3.5 3.5
newton: 4 4
newton: 4.5 4.5
newton: 5 5
newton: 5.5 5.5
newton: 6 6
newton: 6.5 6.5
```

### Описание алгоритма. Линейная интерполяция
```elixir
def interpolate(x, points) do
    points = Enum.sort(points)

    Enum.reduce_while(points, nil, fn {x2, y2}, prev ->
      case prev do
        nil ->
          {:cont, {x2, y2}}

        {x1, y1} when x >= x1 and x <= x2 ->
          y = y1 + (y2 - y1) * (x - x1) / (x2 - x1)
          {:halt, {:ok, y}}

        _ ->
          {:cont, {x2, y2}}
      end
```
### Описание алгоритма. Метод Ньютона
Построение таблицы конечных разностей
```elixir
defp build_difference_table(points) do
    n = length(points)
    initial_table = for i <- 0..(n - 1), do: [elem(Enum.at(points, i), 1)]

    Enum.reduce(1..(n - 1), initial_table, &build_table_row(&1, &2, points, n))
  end
```

Полином Ньютона
```elixir
defp evaluate_polynomial(table, x, points) do
    try do
      n = length(points)
      result = Enum.at(Enum.at(table, 0), 0)
      product = 1.0

      final_result =
        Enum.reduce(1..(n - 1), {result, product}, fn i, {acc, prod} ->
          {xi, _} = Enum.at(points, i - 1)
          new_product = prod * (x - xi)
          new_acc = acc + Enum.at(Enum.at(table, 0), i) * new_product
          {new_acc, new_product}
        end)

      {:ok, elem(final_result, 0)}
end
```

### Input
```elixir
def read_loop(server_pid) do
    case IO.read(:line) do
      :eof ->
        GenServer.cast(server_pid, :eof)

      line ->
        line |> String.trim() |> process_line(server_pid)
        read_loop(server_pid)
    end
  end
```

### Output
```elixir
def print_results(results) do
    results
    |> Stream.each(fn {alg, x, y} ->
      IO.puts("#{alg}: #{format(x)} #{format(y)}")
    end)
    |> Stream.run()
  end
```
### GenServer
Инициализация
```elixir
def init(opts) do
    state = %{
      points: [],
      algorithms: init_algorithms(opts),
      step: opts[:step] || 0.1,
      newton_n: opts[:newton] || 3
    }

    {:ok, state}
end
```
Отправка сообщений
```elixir
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
```

