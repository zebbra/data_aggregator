defmodule DataAggregator.Misc.Coordinates do
  @moduledoc """
    module to convert coordinates from LV95 to WGS84 and vise versa
  """
  alias __MODULE__

  defstruct e: 0.0, n: 0.0

  @type t :: %Coordinates{}

  @doc """
    converts the projection coordinates E (easting) and N (northing)
    in LV95 into the lat and long in WGS84
  """
  @spec lv95_to_wgs84!(Coordinates.t()) :: Coordinates.t()
  def lv95_to_wgs84!(coord) do
    y = (coord.e - 2_600_000.0) / 1_000_000.0
    x = (coord.n - 1_200_000.0) / 1_000_000.0

    # calculate longitude lambda and latitude phi in the unit [10000"]
    lambda =
      2.6779094 +
        4.728982 * y +
        0.791484 * y * x +
        0.1306 * y * Float.pow(x, 2.0) -
        0.0436 * Float.pow(y, 3.0)

    phi =
      16.9023892 +
        3.238272 * x -
        0.270978 * Float.pow(y, 2.0) -
        0.002528 * Float.pow(x, 2.0) -
        0.0447 * Float.pow(y, 2.0) * x -
        0.0140 * Float.pow(x, 3.0)

    # convert longitude and latitude to the unit [°]
    e = lambda * 100.0 / 36.0
    n = phi * 100.0 / 36.0

    # return the result as wgs84 coordinates
    %Coordinates{e: e, n: n}
  end

  @doc """
    converts the projection coordinates E (easting) and N (northing)
    in LV03 into the lat and long in WGS84
  """
  @spec lv03_to_wgs84!(Coordinates.t()) :: Coordinates.t()
  def lv03_to_wgs84!(coord) do
    coord |> lv03_to_lv95!() |> lv95_to_wgs84!()
  end

  @doc """
    converts the lat and long in WGS84 to the projection coordinates E (easting) and N (northing) in LV95
  """
  @spec wgs84_to_lv95!(Coordinates.t()) :: Coordinates.t()
  def wgs84_to_lv95!(coord) do
    # convert the ellipsoidal latitudes phi and longitudes lambda into arcseconds ["] then
    # calculate the auxiliary values (differences of latitude and longitude
    # relative to Bern in the unit [10_000"]):
    phi = (coord.n * 3600 - 169_028.66) / 10_000
    lambda = (coord.e * 3600 - 26_782.5) / 10_000

    # calculate projection coordinates in LV95 (E, N)
    e =
      2_600_072.37 +
        211_455.93 * lambda -
        10_938.51 * lambda * phi -
        0.36 * lambda * Float.pow(phi, 2) -
        44.54 * Float.pow(lambda, 3)

    n =
      1_200_147.07 +
        308_807.95 * phi +
        3745.25 * Float.pow(lambda, 2) +
        76.63 * Float.pow(phi, 2) -
        194.56 * Float.pow(lambda, 2) * phi +
        119.79 * Float.pow(phi, 3)

    # return the result as lv95 coordinates
    %Coordinates{e: e, n: n}
  end

  @doc """
    converts the lat and long in WGS84 to the projection coordinates E (easting) and N (northing) in LV03
  """
  @spec wgs84_to_lv03!(Coordinates.t()) :: Coordinates.t()
  def wgs84_to_lv03!(coord) do
    coord |> wgs84_to_lv95!() |> lv95_to_lv03!()
  end

  @spec lv95_to_lv03!(Coordinates.t()) :: Coordinates.t()
  def lv95_to_lv03!(coord) do
    y = coord.e - 2_000_000.0
    x = coord.n - 1_000_000.0

    %Coordinates{e: y, n: x}
  end

  @spec lv03_to_lv95!(Coordinates.t()) :: Coordinates.t()
  def lv03_to_lv95!(coord) do
    e = coord.e + 2_000_000.0
    n = coord.n + 1_000_000.0

    %Coordinates{e: e, n: n}
  end
end
