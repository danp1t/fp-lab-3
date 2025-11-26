defmodule Interpolation.CLI do
  @moduledoc """
  Командный интерфейс для программы интерполяции.
  Обрабатывает аргументы командной строки и запускает соответствующие алгоритмы.
  """
  def main(args) do
    {opts, _, errors} =
      OptionParser.parse(args,
        switches: [linear: :boolean, newton: :integer, step: :float, help: :boolean],
        aliases: [l: :linear, n: :newton, s: :step, h: :help]
      )

    cond do
      opts[:help] ->
        print_help()

      errors != [] ->
        IO.puts("Ошибка: Не удалось определить аргументы #{inspect(errors)}")
        print_help()

      is_nil(opts[:linear]) and is_nil(opts[:newton]) ->
        print_help()

      true ->
        start_interpolation(opts)
    end
  end

  defp start_interpolation(opts) do
    {:ok, pid} = Interpolation.Server.start_link(opts)
    Interpolation.Input.read_loop(pid)
  end

  defp print_help do
    IO.puts("""
    Usage: ./interpolation [OPTIONS]
    Options:
      -l, --linear    Используем линейную интерполяцию
      -n, --newton N  Используем интерполяцию методом Ньютона
      -s, --step STEP Размер шага (по умолчанию: 0.1)
      -h, --help      Показ справки
    """)
  end
end
