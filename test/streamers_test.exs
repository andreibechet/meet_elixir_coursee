defmodule StreamersTest do
  use ExUnit.Case, async: true

  doctest Streamers

  test "find index file in a directory" do
    assert Streamers.find_index("test/fixtures/emberjs") == "9af0270acb795f9dcafb5c51b1907628.m3u8"
  end

  test "returns nil for not available" do
    assert Streamers.find_index("test/fixtures/not_available") == nil
  end
end
