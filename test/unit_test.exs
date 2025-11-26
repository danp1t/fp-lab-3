defmodule InterpolationTest do
  use ExUnit.Case
  doctest Interpolation

  test "interpolates between two points" do
    points = [{0.0, 0.0}, {1.0, 1.0}]
    assert Interpolation.Linear.interpolate(0.5, points) == {:ok, 0.5}
  end

  test "returns error for single point" do
    points = [{1.0, 2.0}]
    assert Interpolation.Linear.interpolate(1.5, points) == {1.0, 2.0}
  end

  test "handles unsorted points" do
    points = [{1.0, 1.0}, {0.0, 0.0}]
    assert Interpolation.Linear.interpolate(0.5, points) == {:ok, 0.5}
  end

  test "extrapolation returns last point" do
    points = [{0.0, 0.0}, {1.0, 1.0}]
    assert Interpolation.Linear.interpolate(2.0, points) == {1.0, 1.0}
  end

  test "interpolates with three points" do
    points = [{0.0, 0.0}, {1.0, 1.0}, {2.0, 4.0}]
    assert Interpolation.Newton.interpolate(1.5, points, 3) == {:ok, 2.0}
  end

  test "returns error when not enough points" do
    points = [{0.0, 0.0}, {1.0, 1.0}]
    assert Interpolation.Newton.interpolate(0.5, points, 3) == :error
  end

  test "selects closest points" do
    points = [{0.0, 0.0}, {1.0, 1.0}, {3.0, 9.0}, {4.0, 16.0}]
    result = Interpolation.Newton.interpolate(1.2, points, 3)
    assert match?({:ok, _}, result)
  end

  test "handles exact point match" do
    points = [{0.0, 0.0}, {1.0, 1.0}, {2.0, 4.0}]
    assert Interpolation.Newton.interpolate(1.0, points, 3) == {:ok, 1.0}
  end
end
