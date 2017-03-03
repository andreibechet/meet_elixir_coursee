defmodule Streamers do
  @moduledoc """
  Documentation for Streamers.
  """

  require Record
  Record.defrecord :m3u8, [program_id: nil, path: nil, bandwidth: nil, ts_files: []]

  @doc """
  Find streaming index file in the given directory.

  ## Examples
    iex> Streamers.find_index("this/doesnt/exist")
    nil
  """
  def find_index(directory) do
    files = Path.join(directory, "*.m3u8")
    if file = Enum.find(Path.wildcard(files), fn(file) -> is_index?(file) end) do # can also be written is_index?(&1)
      file
    end
  end

  def is_index?(file) do
    File.open!(file,
      fn(pid) -> IO.read(pid, 25) == "#EXTM3U\n#EXT-X-STREAM-INF" end)
  end

  @doc """
  Extract M3U8 records form the index file.
  """
  def extract_m3u8(index_file) do
    []
    File.open!(index_file,
      fn(pid) ->
        IO.read(pid, :line) # ignore the first line
        do_extract_m3u8(pid, Path.dirname(index_file), [])
      end)
  end

  defp do_extract_m3u8(pid, dir, acc) do
    case IO.read(pid, :line) do
      :eof -> Enum.reverse(acc)
      stream_inf ->
        path = IO.read(pid, :line)
        do_extract_m3u8(pid, dir, stream_inf, path, acc)
    end
  end

  defp do_extract_m3u8(pid, dir, stream_inf, path, acc) do
    # expecting #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=110000
    << "#EXT-X-STREAM-INF:PROGRAM-ID=", program_id, ",BANDWIDTH=", bandwidth :: binary >> = stream_inf
    # program_id is 1 char; the bandwidth is marked as binary since we don't know how many bits are left

    path = Path.join(dir, path |> String.strip)
    bandwidth = bandwidth |> String.strip |> String.to_integer
    record = m3u8(program_id: program_id - ?0, path: path, bandwidth: bandwidth )
    # do the - ?0 in order to convert it from ascii to actual int value (ascii start at 48)
    do_extract_m3u8(pid, dir, [record | acc])
  end

  @doc """
  Process M3U* records to get the ts_files
  """
  def process_m3u8(m3u8s) do
    Enum.map(m3u8s, &do_parallel_process_m3u8(&1, self())) # process_m3u8 is public and the do_.. refers to the private method
    do_collect_m3u8(length(m3u8s), [])
  end

  defp do_collect_m3u8(0, acc), do: acc

  defp do_collect_m3u8(count, acc) do
    receive do
      { :m3u8, updated_m3u8 } ->
        do_collect_m3u8(count - 1, [ updated_m3u8 | acc ])
    end
  end

  defp do_parallel_process_m3u8(m3u8, parent_pid) do
    spawn_link(fn ->
      updated_m3u8 = do_process_m3u8(m3u8)
      send(parent_pid, {:m3u8, updated_m3u8})
    end)
  end

  defp do_process_m3u8(m3u8(path: path) = m3u8) do # you match for what's to the left but you still get the whole structure in the right
    File.open!(path,
      fn(pid) ->
        IO.read(pid, :line) # discards #EXTM3U
        IO.read(pid, :line)
        files = do_process_m3u8(pid, [])
        m3u8(m3u8, ts_files: files)
      end)
  end

  defp do_process_m3u8(pid, acc) do
    case IO.read(pid, :line) do
      "#EXT-X-ENDLIST\n" -> Enum.reverse(acc)
      _ext_inf -> # discards #EXTINF:10, => basically when you read something, ignore this line and than read the next
        # prepend a variable with _ to mark it as intentionally unused
        # process: 265c58c98c2d8b04f21ea9d7b73ee4af-00001.ts
        file = IO.read(pid, :line) |> String.strip
        do_process_m3u8(pid, [file | acc])
    end
  end

end
