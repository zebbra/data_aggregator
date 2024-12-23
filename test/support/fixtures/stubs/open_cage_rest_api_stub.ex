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

  defp match_fetch(%{q: "Switzerland"}) do
    {:ok,
     %Req.Response{
       status: 200,
       body: %{
         "documentation" => "https://opencagedata.com/api",
         "licenses" => [
           %{
             "name" => "see attribution guide",
             "url" => "https://opencagedata.com/credits"
           }
         ],
         "rate" => %{"limit" => 2500, "remaining" => 2496, "reset" => 1_729_036_800},
         "results" => [
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 47.8084544, "lng" => 10.4922941},
               "southwest" => %{"lat" => 45.8179447, "lng" => 5.9559113}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "_category" => "place",
               "_type" => "country",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch"
             },
             "confidence" => 1,
             "formatted" => "Switzerland",
             "geometry" => %{"lat" => 46.7985624, "lng" => 8.2319736}
           }
         ],
         "status" => %{"code" => 200, "message" => "OK"},
         "stay_informed" => %{
           "blog" => "https://blog.opencagedata.com",
           "mastodon" => "https://en.osm.town/@opencage"
         },
         "thanks" => "For using an OpenCage API",
         "timestamp" => %{
           "created_http" => "Tue, 15 Oct 2024 07:50:42 GMT",
           "created_unix" => 1_728_978_642
         },
         "total_results" => 1
       }
     }}
  end

  defp match_fetch(%{q: "Vaud, Switzerland"}) do
    {:ok,
     %Req.Response{
       status: 200,
       body: %{
         "documentation" => "https://opencagedata.com/api",
         "licenses" => [
           %{
             "name" => "see attribution guide",
             "url" => "https://opencagedata.com/credits"
           }
         ],
         "rate" => %{"limit" => 2500, "remaining" => 2495, "reset" => 1_729_036_800},
         "results" => [
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 46.9867207, "lng" => 7.2491896},
               "southwest" => %{"lat" => 46.1870679, "lng" => 6.0638578}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "ISO_3166-2" => ["CH-VD"],
               "_category" => "place",
               "_type" => "state",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "state" => "Vaud",
               "state_code" => "VD"
             },
             "confidence" => 1,
             "formatted" => "Vaud, Switzerland",
             "geometry" => %{"lat" => 46.6356963, "lng" => 6.5320717}
           }
         ],
         "status" => %{"code" => 200, "message" => "OK"},
         "stay_informed" => %{
           "blog" => "https://blog.opencagedata.com",
           "mastodon" => "https://en.osm.town/@opencage"
         },
         "thanks" => "For using an OpenCage API",
         "timestamp" => %{
           "created_http" => "Tue, 15 Oct 2024 08:05:11 GMT",
           "created_unix" => 1_728_979_511
         },
         "total_results" => 1
       }
     }}
  end

  defp match_fetch(%{q: "Bern, Switzerland"}) do
    {:ok,
     %Req.Response{
       status: 200,
       body: %{
         "documentation" => "https://opencagedata.com/api",
         "licenses" => [
           %{
             "name" => "see attribution guide",
             "url" => "https://opencagedata.com/credits"
           }
         ],
         "rate" => %{"limit" => 2500, "remaining" => 2494, "reset" => 1_729_036_800},
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
           "created_http" => "Tue, 15 Oct 2024 08:11:26 GMT",
           "created_unix" => 1_728_979_886
         },
         "total_results" => 2
       }
     }}
  end

  defp match_fetch(%{q: "46.086797,7.104789"}) do
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
         "rate" => %{"limit" => 2500, "remaining" => 2498, "reset" => 1_730_246_400},
         "results" => [
           %{
             "bounds" => %{
               "northeast" => %{"lat" => 46.088489, "lng" => 7.106615},
               "southwest" => %{"lat" => 46.0881359, "lng" => 7.1049418}
             },
             "components" => %{
               "ISO_3166-1_alpha-2" => "CH",
               "ISO_3166-1_alpha-3" => "CHE",
               "ISO_3166-2" => ["CH-VS"],
               "_category" => "road",
               "_normalized_city" => "Val de Bagnes",
               "_type" => "road",
               "continent" => "Europe",
               "country" => "Switzerland",
               "country_code" => "ch",
               "county" => "Entremont",
               "local_administrative_area" => "Val de Bagnes",
               "municipality" => "Val de Bagnes",
               "postcode" => "1934",
               "road" => "Route du Coteau",
               "road_type" => "residential",
               "state" => "Wallis",
               "state_code" => "VS"
             },
             "confidence" => 9,
             "distance_from_q" => %{"meters" => 184},
             "formatted" => "Route du Coteau, 1934 Val de Bagnes, Switzerland",
             "geometry" => %{"lat" => 46.0884374, "lng" => 7.1051661}
           }
         ],
         "status" => %{"code" => 200, "message" => "OK"},
         "stay_informed" => %{
           "blog" => "https://blog.opencagedata.com",
           "mastodon" => "https://en.osm.town/@opencage"
         },
         "thanks" => "For using an OpenCage API",
         "timestamp" => %{
           "created_http" => "Tue, 29 Oct 2024 10:48:40 GMT",
           "created_unix" => 1_730_198_920
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
end
