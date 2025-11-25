defmodule Interpolation.CLI do
  def main(args) do
    case OptionParser.parse(args,
      switches: [
        linear: :boolean,
        newton: :integer,
        step: :float,
        help: :boolean
      ],
      aliases: [
        l: :linear,
        n: :newton,
        s: :step,
        h: :help
      ]
    ) do
      {opts, _, []} ->
        has_algorithm = opts[:linear] || !is_nil(opts[:newton])

        if opts[:help] || !has_algorithm do
          print_help()
        else
          start_interpolation(opts)
        end

      {_opts, _args, errors} ->
        IO.puts("Error parsing arguments: #{inspect errors}")
        print_help()
    end
  end

  defp start_interpolation(opts) do
    {:ok, pid} = Interpolation.Server.start_link(opts)
    Interpolation.Input.read_loop(pid)
  end

  defp print_help do
    IO.puts("""
    Usage: interpolation [OPTIONS]

    Options:
      -l, --linear          Use linear interpolation
      -n, --newton N        Use Newton interpolation with N points
      -s, --step STEP       Step for output points (default: 0.1)
      -h, --help            Show this help

    Examples:
      cat data.csv | interpolation --linear --step 0.5
      cat data.csv | interpolation --newton 4 --step 0.2
      cat data.csv | interpolation --linear --newton 3 --step 0.1
    """)
  end
end
