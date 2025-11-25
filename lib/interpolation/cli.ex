defmodule Interpolation.CLI do
  def main(args) do
    {opts, _, errors} = OptionParser.parse(args,
      switches: [linear: :boolean, newton: :integer, step: :float, help: :boolean],
      aliases: [l: :linear, n: :newton, s: :step, h: :help]
    )

    cond do
      opts[:help] -> print_help()
      errors != [] ->
        IO.puts("Error parsing arguments: #{inspect errors}")
        print_help()
      is_nil(opts[:linear]) and is_nil(opts[:newton]) -> print_help()
      true -> start_interpolation(opts)
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
      -l, --linear    Use linear interpolation
      -n, --newton N  Use Newton interpolation with N points
      -s, --step STEP Step size (default: 0.1)
      -h, --help      Show this help
    """)
  end
end
