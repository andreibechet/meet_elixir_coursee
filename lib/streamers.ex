defmodule Streamers do
  @moduledoc """
  Documentation for Streamers.
  """

  @doc """
  Find streaming index file in the given directory.

  ## Examples
    iex> Streamers.find_index("this/doesnt/exist")
    nil
  """
  def find_index(directory) do
    files = Path.join(directory, "*.m3u8")
    if file = Enum.find(Path.wildcard(files), fn(file) -> is_index?(file) end) do # can also be written is_index?(&1)
      Path.basename(file)
    end
  end

  def is_index?(file) do
    File.open!(file,
      fn(pid) -> IO.read(pid, 25) == "#EXTM3U\n#EXT-X-STREAM-INF" end)
  end

end
