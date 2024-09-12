defmodule DataAggregator.Opencage.RestAPIStub do
  @moduledoc """
  Module to interact with the Opencage Rest API in tests. Subs the real RestAPI module, so no api requests will be made.

  Note while stubbing:

      note for anyone facing the issue of having his/her stub/expect not called:
      make sure that the function you are stubbing/expecting is called NOT within the
      same module the function is declared!

      clean design helps: move stubable functions and api clients to a separate modules

      https://github.com/edgurgel/mimic/issues/27

  """

  def fetch(params) when is_list(params) do
    q = Keyword.get(params, :q)

    match_fetch(%{q: q})
  end

  defp match_fetch(%{q: "46.946660986374766,7.456905642729698"}) do
    {:ok,
     %{
       status: 200,
       body: %{
         "documentation" => "https://opencagedata.com/api",
         "licenses" => [
           %{
             "name" => "see attribution guide",
             "url" => "https://opencagedata.com/credits"
           }
         ],
         "rate" => %{"limit" => 2500, "remaining" => 2459, "reset" => 1_721_692_800},
         "results" => [
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 46.9467468, "lng" => 7.4570141},
               "southwest" => %{"lat" => 46.9466468, "lng" => 7.4569141}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "ISO_3166-2" => ["CH-BE"],
               "_category" => "building",
               "_normalized_city" => "Bern",
               "_type" => "building",
               "city" => "Bern",
               "city_district" => "Stadtteil I",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "Bern-Mittelland administrative district",
               "local_administrative_area" => "Bern",
               "office" => "stepping stone",
               "postcode" => "3011",
               "quarter" => "Matte",
               "road" => "Wasserwerkgasse",
               "state" => "Bern",
               "state_code" => "BE",
               "state_district" => "Bernese Mittelland administrative region"
             },
             "confidence" => 10,
             "distance_from_q" => %{"meters" => 5},
             "formatted" => "stepping stone, Wasserwerkgasse, 3011 Bern, Switzerland",
             "geometry" => %{"lat" => 46.9466968, "lng" => 7.4569641}
           }
         ],
         "status" => %{"code" => 200, "message" => "OK"},
         "stay_informed" => %{
           "blog" => "https://blog.opencagedata.com",
           "mastodon" => "https://en.osm.town/@opencage"
         },
         "thanks" => "For using an OpenCage API",
         "timestamp" => %{
           "created_http" => "Mon, 22 Jul 2024 14:40:07 GMT",
           "created_unix" => 1_721_659_207
         },
         "total_results" => 1
       }
     }}
  end

  defp match_fetch(%{q: "4242.4242,2424.2424"}) do
    {:ok,
     %{
       status: 400,
       body: %{
         "documentation" => "https://opencagedata.com/api",
         "licenses" => [
           %{
             "name" => "see attribution guide",
             "url" => "https://opencagedata.com/credits"
           }
         ],
         "rate" => %{"limit" => 2500, "remaining" => 2455, "reset" => 1_721_692_800},
         "results" => [],
         "status" => %{"code" => 400, "message" => "invalid coordinates"},
         "stay_informed" => %{
           "blog" => "https://blog.opencagedata.com",
           "mastodon" => "https://en.osm.town/@opencage"
         },
         "thanks" => "For using an OpenCage API",
         "timestamp" => %{
           "created_http" => "Mon, 22 Jul 2024 14:41:09 GMT",
           "created_unix" => 1_721_659_269
         },
         "total_results" => 0
       }
     }}
  end

  defp match_fetch(%{q: "Liebefeld, Bern"}) do
    {:ok,
     %{
       status: 200,
       body: %{
         "documentation" => "https://opencagedata.com/api",
         "licenses" => [
           %{
             "name" => "see attribution guide",
             "url" => "https://opencagedata.com/credits"
           }
         ],
         "rate" => %{"limit" => 2500, "remaining" => 2462, "reset" => 1_721_692_800},
         "results" => [
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 46.9368183, "lng" => 7.4384602},
               "southwest" => %{"lat" => 46.9249408, "lng" => 7.4070798}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "ISO_3166-2" => ["CH-BE"],
               "_category" => "place",
               "_normalized_city" => "Köniz",
               "_type" => "neighbourhood",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "Bern-Mittelland administrative district",
               "local_administrative_area" => "Köniz",
               "postcode" => "3097",
               "state" => "Bern",
               "state_code" => "BE",
               "state_district" => "Bernese Mittelland administrative region",
               "suburb" => "Liebefeld",
               "town" => "Köniz"
             },
             "confidence" => 8,
             "formatted" => "3097 Köniz, Switzerland",
             "geometry" => %{"lat" => 46.9322404, "lng" => 7.4204692}
           },
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 47.0098205, "lng" => 7.5210625},
               "southwest" => %{"lat" => 46.9176275, "lng" => 7.377458}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "_category" => "place",
               "_normalized_city" => "Bern",
               "_type" => "city",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "Bern-Mittelland District",
               "local_administrative_area" => "Bern",
               "state" => "Bern",
               "state_code" => "BE",
               "town" => "Bern"
             },
             "confidence" => 6,
             "formatted" => "Bern, Bern-Mittelland District, Switzerland",
             "geometry" => %{"lat" => 46.94809, "lng" => 7.44744}
           }
         ],
         "status" => %{"code" => 200, "message" => "OK"},
         "stay_informed" => %{
           "blog" => "https://blog.opencagedata.com",
           "mastodon" => "https://en.osm.town/@opencage"
         },
         "thanks" => "For using an OpenCage API",
         "timestamp" => %{
           "created_http" => "Mon, 22 Jul 2024 14:40:07 GMT",
           "created_unix" => 1_721_659_207
         },
         "total_results" => 2
       }
     }}
  end

  defp match_fetch(%{q: "Bern, Switzerland"}) do
    {:ok,
     %{
       status: 200,
       body: %{
         "documentation" => "https://opencagedata.com/api",
         "licenses" => [
           %{
             "name" => "see attribution guide",
             "url" => "https://opencagedata.com/credits"
           }
         ],
         "rate" => %{"limit" => 2500, "remaining" => 2464, "reset" => 1_721_692_800},
         "results" => [
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 46.9901527, "lng" => 7.4955563},
               "southwest" => %{"lat" => 46.9190326, "lng" => 7.2943145}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "ISO_3166-2" => ["CH-BE"],
               "_category" => "place",
               "_normalized_city" => "Bern",
               "_type" => "city",
               "city" => "Bern",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "Bern-Mittelland administrative district",
               "local_administrative_area" => "Bern",
               "state" => "Bern",
               "state_code" => "BE",
               "state_district" => "Bernese Mittelland administrative region"
             },
             "confidence" => 6,
             "formatted" => "Bern, Bern-Mittelland, Switzerland",
             "geometry" => %{"lat" => 46.9484742, "lng" => 7.4521749}
           },
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 47.3453097, "lng" => 8.4551574},
               "southwest" => %{"lat" => 46.3265189, "lng" => 6.8614832}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "ISO_3166-2" => ["CH-BE"],
               "_category" => "place",
               "_type" => "state",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "state" => "Bern",
               "state_code" => "BE"
             },
             "confidence" => 1,
             "formatted" => "Bern, Switzerland",
             "geometry" => %{"lat" => 46.8382351, "lng" => 7.6004502}
           }
         ],
         "status" => %{"code" => 200, "message" => "OK"},
         "stay_informed" => %{
           "blog" => "https://blog.opencagedata.com",
           "mastodon" => "https://en.osm.town/@opencage"
         },
         "thanks" => "For using an OpenCage API",
         "timestamp" => %{
           "created_http" => "Mon, 22 Jul 2024 14:40:07 GMT",
           "created_unix" => 1_721_659_207
         },
         "total_results" => 2
       }
     }}
  end

  defp match_fetch(%{q: "Europe, Lausanne, Vaud, Switzerland"}) do
    {:ok,
     %{
       status: 200,
       body: %{
         "documentation" => "https://opencagedata.com/api",
         "licenses" => [
           %{
             "name" => "see attribution guide",
             "url" => "https://opencagedata.com/credits"
           }
         ],
         "rate" => %{"limit" => 2500, "remaining" => 2465, "reset" => 1_721_692_800},
         "results" => [
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 46.5210645, "lng" => 6.6312873},
               "southwest" => %{"lat" => 46.5203965, "lng" => 6.6302231}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "ISO_3166-2" => ["CH-VD"],
               "_category" => "road",
               "_normalized_city" => "Lausanne",
               "_type" => "road",
               "city" => "Lausanne",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "District de Lausanne",
               "local_administrative_area" => "Lausanne",
               "postcode" => "1003",
               "road" => "Place de l'Europe",
               "road_type" => "pedestrian",
               "state" => "Vaud",
               "state_code" => "VD"
             },
             "confidence" => 9,
             "formatted" => "Place de l'Europe, 1003 Lausanne, Switzerland",
             "geometry" => %{"lat" => 46.5207656, "lng" => 6.6306324}
           },
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 46.5197102, "lng" => 6.6320068},
               "southwest" => %{"lat" => 46.519665, "lng" => 6.6319809}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "ISO_3166-2" => ["CH-VD"],
               "_category" => "road",
               "_normalized_city" => "Lausanne",
               "_type" => "road",
               "city" => "Lausanne",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "District de Lausanne",
               "local_administrative_area" => "Lausanne",
               "postcode" => "1003",
               "road" => "Zwischengeschoss Place de l'Europe",
               "road_type" => "footway",
               "state" => "Vaud",
               "state_code" => "VD"
             },
             "confidence" => 9,
             "formatted" => "Zwischengeschoss Place de l'Europe, 1003 Lausanne, Switzerland",
             "geometry" => %{"lat" => 46.519665, "lng" => 6.6319809}
           },
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 46.5161602, "lng" => 6.6286547},
               "southwest" => %{"lat" => 46.5160602, "lng" => 6.6285547}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "ISO_3166-2" => ["CH-VD"],
               "_category" => "commerce",
               "_normalized_city" => "Lausanne",
               "_type" => "restaurant",
               "city" => "Lausanne",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "District de Lausanne",
               "house_number" => "33",
               "local_administrative_area" => "Lausanne",
               "postcode" => "1006",
               "restaurant" => "Café de l'Europe",
               "road" => "Rue du Simplon",
               "state" => "Vaud",
               "state_code" => "VD"
             },
             "confidence" => 9,
             "formatted" => "Café de l'Europe, Rue du Simplon 33, 1006 Lausanne, Switzerland",
             "geometry" => %{"lat" => 46.5161102, "lng" => 6.6286047}
           },
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 46.5204381, "lng" => 6.6313143},
               "southwest" => %{"lat" => 46.5203381, "lng" => 6.6312143}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "ISO_3166-2" => ["CH-VD"],
               "_category" => "commerce",
               "_normalized_city" => "Lausanne",
               "_type" => "bicycle_rental",
               "bicycle_rental" => "Place de l'Europe",
               "city" => "Lausanne",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "District de Lausanne",
               "local_administrative_area" => "Lausanne",
               "postcode" => "1003",
               "road" => "Place de l'Europe",
               "state" => "Vaud",
               "state_code" => "VD"
             },
             "confidence" => 9,
             "formatted" => "Place de l'Europe, 1003 Lausanne, Switzerland",
             "geometry" => %{"lat" => 46.5203881, "lng" => 6.6312643}
           },
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 46.564254, "lng" => 6.702663},
               "southwest" => %{"lat" => 46.504254, "lng" => 6.541501}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "_category" => "place",
               "_normalized_city" => "Lausanne",
               "_type" => "city",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "Lausanne District",
               "local_administrative_area" => "Lausanne",
               "state" => "Vaud",
               "state_code" => "VD",
               "town" => "Lausanne"
             },
             "confidence" => 7,
             "formatted" => "Lausanne, Lausanne District, Switzerland",
             "geometry" => %{"lat" => 46.516, "lng" => 6.63282}
           }
         ],
         "status" => %{"code" => 200, "message" => "OK"},
         "stay_informed" => %{
           "blog" => "https://blog.opencagedata.com",
           "mastodon" => "https://en.osm.town/@opencage"
         },
         "thanks" => "For using an OpenCage API",
         "timestamp" => %{
           "created_http" => "Mon, 22 Jul 2024 14:40:06 GMT",
           "created_unix" => 1_721_659_206
         },
         "total_results" => 5
       }
     }}
  end

  defp match_fetch(%{q: "Vaux-sur-Morges, Canton de Vaud, Vaud, Switzerland"}) do
    {:ok,
     %{
       status: 200,
       body: %{
         "documentation" => "https://opencagedata.com/api",
         "licenses" => [
           %{
             "name" => "see attribution guide",
             "url" => "https://opencagedata.com/credits"
           }
         ],
         "rate" => %{"limit" => 2500, "remaining" => 2465, "reset" => 1_721_692_800},
         "results" => [
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 46.5210645, "lng" => 6.6312873},
               "southwest" => %{"lat" => 46.5203965, "lng" => 6.6302231}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "ISO_3166-2" => ["CH-VD"],
               "_category" => "road",
               "_normalized_city" => "Vaux-sur-Morges",
               "_type" => "road",
               "city" => "Vaux-sur-Morges",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "District de Vaux-sur-Morges",
               "local_administrative_area" => "Vaux-sur-Morges",
               "postcode" => "1003",
               "road" => "Place de l'Europe",
               "road_type" => "pedestrian",
               "state" => "Vaud",
               "state_code" => "VD"
             },
             "confidence" => 9,
             "formatted" => "Place de l'Europe, 1003 Vaux-sur-Morges, Switzerland",
             "geometry" => %{"lat" => 46.5207656, "lng" => 6.6306324}
           },
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 46.5197102, "lng" => 6.6320068},
               "southwest" => %{"lat" => 46.519665, "lng" => 6.6319809}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "ISO_3166-2" => ["CH-VD"],
               "_category" => "road",
               "_normalized_city" => "Vaux-sur-Morges",
               "_type" => "road",
               "city" => "Vaux-sur-Morges",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "District de Vaux-sur-Morges",
               "local_administrative_area" => "Vaux-sur-Morges",
               "postcode" => "1003",
               "road" => "Zwischengeschoss Place de l'Europe",
               "road_type" => "footway",
               "state" => "Vaud",
               "state_code" => "VD"
             },
             "confidence" => 9,
             "formatted" => "Zwischengeschoss Place de l'Europe, 1003 Vaux-sur-Morges, Switzerland",
             "geometry" => %{"lat" => 46.519665, "lng" => 6.6319809}
           },
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 46.5161602, "lng" => 6.6286547},
               "southwest" => %{"lat" => 46.5160602, "lng" => 6.6285547}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "ISO_3166-2" => ["CH-VD"],
               "_category" => "commerce",
               "_normalized_city" => "Vaux-sur-Morges",
               "_type" => "restaurant",
               "city" => "Vaux-sur-Morges",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "District de Vaux-sur-Morges",
               "house_number" => "33",
               "local_administrative_area" => "Vaux-sur-Morges",
               "postcode" => "1006",
               "restaurant" => "Café de l'Europe",
               "road" => "Rue du Simplon",
               "state" => "Vaud",
               "state_code" => "VD"
             },
             "confidence" => 9,
             "formatted" => "Café de l'Europe, Rue du Simplon 33, 1006 Vaux-sur-Morges, Switzerland",
             "geometry" => %{"lat" => 46.5161102, "lng" => 6.6286047}
           },
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 46.5204381, "lng" => 6.6313143},
               "southwest" => %{"lat" => 46.5203381, "lng" => 6.6312143}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "ISO_3166-2" => ["CH-VD"],
               "_category" => "commerce",
               "_normalized_city" => "Vaux-sur-Morges",
               "_type" => "bicycle_rental",
               "bicycle_rental" => "Place de l'Europe",
               "city" => "Vaux-sur-Morges",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "District de Vaux-sur-Morges",
               "local_administrative_area" => "Vaux-sur-Morges",
               "postcode" => "1003",
               "road" => "Place de l'Europe",
               "state" => "Vaud",
               "state_code" => "VD"
             },
             "confidence" => 9,
             "formatted" => "Place de l'Europe, 1003 Vaux-sur-Morges, Switzerland",
             "geometry" => %{"lat" => 46.5203881, "lng" => 6.6312643}
           },
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 46.564254, "lng" => 6.702663},
               "southwest" => %{"lat" => 46.504254, "lng" => 6.541501}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "_category" => "place",
               "_normalized_city" => "Vaux-sur-Morges",
               "_type" => "city",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "Vaux-sur-Morges District",
               "local_administrative_area" => "Vaux-sur-Morges",
               "state" => "Vaud",
               "state_code" => "VD",
               "town" => "Vaux-sur-Morges"
             },
             "confidence" => 7,
             "formatted" => "Vaux-sur-Morges, Vaux-sur-Morges District, Switzerland",
             "geometry" => %{"lat" => 46.516, "lng" => 6.63282}
           }
         ],
         "status" => %{"code" => 200, "message" => "OK"},
         "stay_informed" => %{
           "blog" => "https://blog.opencagedata.com",
           "mastodon" => "https://en.osm.town/@opencage"
         },
         "thanks" => "For using an OpenCage API",
         "timestamp" => %{
           "created_http" => "Mon, 22 Jul 2024 14:40:06 GMT",
           "created_unix" => 1_721_659_206
         },
         "total_results" => 5
       }
     }}
  end

  defp match_fetch(%{q: "46.946659297095934,7.456910040693462"}) do
    {:ok,
     %{
       status: 200,
       body: %{
         "documentation" => "https://opencagedata.com/api",
         "licenses" => [
           %{
             "name" => "see attribution guide",
             "url" => "https://opencagedata.com/credits"
           }
         ],
         "rate" => %{"limit" => 2500, "remaining" => 2461, "reset" => 1_721_692_800},
         "results" => [
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 46.9467468, "lng" => 7.4570141},
               "southwest" => %{"lat" => 46.9466468, "lng" => 7.4569141}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "ISO_3166-2" => ["CH-BE"],
               "_category" => "building",
               "_normalized_city" => "Bern",
               "_type" => "building",
               "city" => "Bern",
               "city_district" => "Stadtteil I",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "Bern-Mittelland administrative district",
               "local_administrative_area" => "Bern",
               "office" => "stepping stone",
               "postcode" => "3011",
               "quarter" => "Matte",
               "road" => "Wasserwerkgasse",
               "state" => "Bern",
               "state_code" => "BE",
               "state_district" => "Bernese Mittelland administrative region"
             },
             "confidence" => 10,
             "distance_from_q" => %{"meters" => 5},
             "formatted" => "stepping stone, Wasserwerkgasse, 3011 Bern, Switzerland",
             "geometry" => %{"lat" => 46.9466968, "lng" => 7.4569641}
           }
         ],
         "status" => %{"code" => 200, "message" => "OK"},
         "stay_informed" => %{
           "blog" => "https://blog.opencagedata.com",
           "mastodon" => "https://en.osm.town/@opencage"
         },
         "thanks" => "For using an OpenCage API",
         "timestamp" => %{
           "created_http" => "Mon, 22 Jul 2024 14:40:07 GMT",
           "created_unix" => 1_721_659_207
         },
         "total_results" => 1
       }
     }}
  end

  defp match_fetch(%{q: "32.117833,20.082039"}) do
    {:ok,
     %{
       status: 200,
       body: %{
         "documentation" => "https://opencagedata.com/api",
         "licenses" => [
           %{
             "name" => "see attribution guide",
             "url" => "https://opencagedata.com/credits"
           }
         ],
         "rate" => %{"limit" => 2500, "remaining" => 2458, "reset" => 1_721_692_800},
         "results" => [
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 32.1193739, "lng" => 20.0851694},
               "southwest" => %{"lat" => 32.1178631, "lng" => 20.0833503}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "LY",
               "ISO_3166-1_alpha-3" => "LBY",
               "ISO_3166-2" => ["LY-BA"],
               "_category" => "education",
               "_normalized_city" => "Benghazi",
               "_type" => "school",
               "city" => "Benghazi",
               "continent" => "Africa",
               "country" => "Libya",
               "country_code" => "ly",
               "road" => "Al Uoroba Highway",
               "school" => "Saleh Boiesser Highschool"
             },
             "confidence" => 9,
             "distance_from_q" => %{"meters" => 227},
             "formatted" => "Saleh Boiesser Highschool, Al Uoroba Highway, Benghazi, Libya",
             "geometry" => %{"lat" => 32.1186424, "lng" => 20.0842558}
           }
         ],
         "status" => %{"code" => 200, "message" => "OK"},
         "stay_informed" => %{
           "blog" => "https://blog.opencagedata.com",
           "mastodon" => "https://en.osm.town/@opencage"
         },
         "thanks" => "For using an OpenCage API",
         "timestamp" => %{
           "created_http" => "Mon, 22 Jul 2024 14:40:07 GMT",
           "created_unix" => 1_721_659_207
         },
         "total_results" => 1
       }
     }}
  end

  defp match_fetch(%{q: "Niesen, Switzerland"}) do
    {:ok,
     %{
       status: 200,
       body: %{
         "documentation" => "https://opencagedata.com/api",
         "licenses" => [
           %{
             "name" => "see attribution guide",
             "url" => "https://opencagedata.com/credits"
           }
         ],
         "rate" => %{"limit" => 2500, "remaining" => 2460, "reset" => 1_721_692_800},
         "results" => [
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 46.6462436, "lng" => 7.6524174},
               "southwest" => %{"lat" => 46.6461436, "lng" => 7.6523174}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "ISO_3166-2" => ["CH-BE"],
               "_category" => "natural/water",
               "_normalized_city" => "Reichenbach im Kandertal",
               "_type" => "peak",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "Frutigen-Niedersimmental administrative district",
               "local_administrative_area" => "Reichenbach im Kandertal",
               "peak" => "Niesen",
               "postcode" => "3752",
               "state" => "Bern",
               "state_code" => "BE",
               "state_district" => "Oberland administrative region",
               "village" => "Reichenbach im Kandertal"
             },
             "confidence" => 9,
             "formatted" => "Niesen, 3752 Reichenbach im Kandertal, Switzerland",
             "geometry" => %{"lat" => 46.6461936, "lng" => 7.6523674}
           },
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 46.7768394, "lng" => 7.9696604},
               "southwest" => %{"lat" => 46.7767394, "lng" => 7.9695604}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "ISO_3166-2" => ["CH-BE"],
               "_category" => "natural/water",
               "_normalized_city" => "Oberried am Brienzersee",
               "_type" => "peak",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "Interlaken-Oberhasli administrative district",
               "local_administrative_area" => "Oberried am Brienzersee",
               "peak" => "Niesen",
               "postcode" => "3854",
               "state" => "Bern",
               "state_code" => "BE",
               "state_district" => "Oberland administrative region",
               "village" => "Oberried am Brienzersee"
             },
             "confidence" => 9,
             "formatted" => "Niesen, 3854 Oberried am Brienzersee, Switzerland",
             "geometry" => %{"lat" => 46.7767894, "lng" => 7.9696104}
           },
           %{
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "_category" => "place",
               "_normalized_city" => "Reichenbach im Kandertal",
               "_type" => "municipality",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "Frutigen-Niedersimmental District",
               "local_administrative_area" => "Reichenbach im Kandertal",
               "state" => "Bern",
               "state_code" => "BE"
             },
             "confidence" => 9,
             "formatted" => "Reichenbach im Kandertal, Frutigen-Niedersimmental District, Switzerland",
             "geometry" => %{"lat" => 46.64631, "lng" => 7.65236}
           }
         ],
         "status" => %{"code" => 200, "message" => "OK"},
         "stay_informed" => %{
           "blog" => "https://blog.opencagedata.com",
           "mastodon" => "https://en.osm.town/@opencage"
         },
         "thanks" => "For using an OpenCage API",
         "timestamp" => %{
           "created_http" => "Mon, 22 Jul 2024 14:40:07 GMT",
           "created_unix" => 1_721_659_207
         },
         "total_results" => 3
       }
     }}
  end
end
