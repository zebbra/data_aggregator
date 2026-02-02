defmodule DataAggregator.CatalogOfLife.RestAPIStub do
  @moduledoc """
  Module to interact with the Catalog of Life Rest API in tests. Subs the real RestAPI module, so no api requests will be made.

  Note while stubbing:

      note for anyone facing the issue of having his/her stub/expect not called:
      make sure that the function you are stubbing/expecting is called NOT within the
      same module the function is declared!

      clean design helps: move stubable functions and api clients to a separate modules

      https://github.com/edgurgel/mimic/issues/27

  """

  @spec parse_name(String.t()) :: {:ok, Req.Response.t()} | {:error, String.t()}
  def parse_name(_unparsed_scientific_name) do
    {:ok,
     %Req.Response{
       status: 200,
       headers: %{
         "accept-ranges" => ["bytes"],
         "age" => ["0"],
         "cache-control" => ["must-revalidate,no-cache,no-store"],
         "content-type" => ["application/json"],
         "date" => ["Fri, 19 Dec 2025 09:22:37 GMT"],
         "vary" => ["Cookie, Accept, Accept-Encoding, Accept-Language, User-Agent", "Origin"],
         "via" => [
           "HTTP/1.1 git.gammaspectra.live/git/go-away@v0.0.0-20250904213329-95ac08540b8c+dirty",
           "1.1 varnish (Varnish/7.1)"
         ],
         "x-backend" => ["api_read_only"],
         "x-cache" => ["miss_uncacheable"],
         "x-varnish" => ["971718287"]
       },
       body: %{
         "authorship" => "(Schenck, 1852)",
         "basionymAuthorship" => %{"authors" => ["Schenck"], "year" => "1852"},
         "basionymOrCombinationAuthorship" => %{
           "authors" => ["Schenck"],
           "year" => "1852"
         },
         "code" => "zoological",
         "genus" => "Anergates",
         "label" => "Anergates atratulus (Schenck, 1852)",
         "labelHtml" => "<i>Anergates atratulus</i> (Schenck, 1852)",
         "parsed" => true,
         "rank" => "species",
         "scientificName" => "Anergates atratulus",
         "specificEpithet" => "atratulus",
         "type" => "scientific"
       },
       trailers: %{},
       private: %{}
     }}
  end

  @spec lookup_species_by_name(String.t()) :: {:ok, Req.Response.t()} | {:error, String.t()}
  def lookup_species_by_name(_scientific_name) do
    {:ok,
     %Req.Response{
       status: 200,
       headers: %{
         "accept-ranges" => ["bytes"],
         "age" => ["0"],
         "cache-control" => ["public, max-age=604800, s-maxage=604800"],
         "content-type" => ["application/json"],
         "date" => ["Mon, 02 Feb 2026 12:54:38 GMT"],
         "vary" => ["Cookie, Accept, Accept-Encoding, Accept-Language, User-Agent", "Origin"],
         "via" => [
           "HTTP/1.1 git.gammaspectra.live/git/go-away@v0.0.0-20250904213329-95ac08540b8c+dirty",
           "1.1 varnish (Varnish/7.1)"
         ],
         "x-backend" => ["api"],
         "x-cache" => ["miss_cached"],
         "x-varnish" => ["101661596"]
       },
       body: %{
         "id" => "DY5M",
         "issues" => %{},
         "match" => true,
         "original" => %{
           "canonical" => true,
           "label" => "Anergates atratulus (Schenck, 1852)",
           "labelHtml" => "Anergates atratulus (Schenck, 1852)",
           "name" => "Anergates atratulus (Schenck, 1852)",
           "status" => "accepted"
         },
         "sectorKey" => 64_431,
         "type" => "exact",
         "usage" => %{
           "authorship" => "(Schenck, 1852)",
           "canonical" => false,
           "canonicalId" => 476_310,
           "classification" => [
             %{
               "authorship" => "(Schenck, 1852)",
               "canonical" => false,
               "canonicalId" => 22_231_880,
               "code" => "zoological",
               "id" => "CMV7J",
               "label" => "Tetramorium atratulum (Schenck, 1852)",
               "labelHtml" => "<i>Tetramorium atratulum</i> (Schenck, 1852)",
               "name" => "Tetramorium atratulum",
               "namesIndexId" => 22_231_881,
               "namesIndexMatchType" => "exact",
               "parent" => "63V54",
               "parentId" => "63V54",
               "rank" => "species",
               "sectorKey" => 64_431,
               "status" => "accepted"
             },
             %{
               "authorship" => "Mayr, 1855",
               "canonical" => false,
               "canonicalId" => 22_229_372,
               "code" => "zoological",
               "id" => "63V54",
               "label" => "Tetramorium Mayr, 1855",
               "labelHtml" => "<i>Tetramorium</i> Mayr, 1855",
               "name" => "Tetramorium",
               "namesIndexId" => 22_229_373,
               "namesIndexMatchType" => "variant",
               "parent" => "CLMZ7",
               "parentId" => "CLMZ7",
               "rank" => "genus",
               "sectorKey" => 64_431,
               "status" => "accepted"
             },
             %{
               "authorship" => "Forel, 1893",
               "canonical" => false,
               "canonicalId" => 6_735_990,
               "code" => "zoological",
               "id" => "CLMZ7",
               "label" => "Crematogastrini Forel, 1893",
               "labelHtml" => "Crematogastrini Forel, 1893",
               "name" => "Crematogastrini",
               "namesIndexId" => 6_735_991,
               "namesIndexMatchType" => "variant",
               "parent" => "CMD7Z",
               "parentId" => "CMD7Z",
               "rank" => "tribe",
               "sectorKey" => 64_431,
               "status" => "accepted"
             },
             %{
               "authorship" => "Lepeletier de Saint-Fargeau, 1835",
               "canonical" => false,
               "canonicalId" => 15_529_398,
               "code" => "zoological",
               "id" => "CMD7Z",
               "label" => "Myrmicinae Lepeletier de Saint-Fargeau, 1835",
               "labelHtml" => "Myrmicinae Lepeletier de Saint-Fargeau, 1835",
               "name" => "Myrmicinae",
               "namesIndexId" => 15_529_407,
               "namesIndexMatchType" => "variant",
               "parent" => "CLRKP",
               "parentId" => "CLRKP",
               "rank" => "subfamily",
               "sectorKey" => 64_431,
               "status" => "accepted"
             },
             %{
               "authorship" => "Latreille, 1802",
               "canonical" => false,
               "canonicalId" => 8_301_485,
               "code" => "zoological",
               "id" => "CLRKP",
               "label" => "Formicidae Latreille, 1802",
               "labelHtml" => "Formicidae Latreille, 1802",
               "name" => "Formicidae",
               "namesIndexId" => 9_882_464,
               "namesIndexMatchType" => "variant",
               "parent" => "VP",
               "parentId" => "VP",
               "rank" => "family",
               "sectorKey" => 64_431,
               "status" => "accepted"
             },
             %{
               "canonical" => false,
               "canonicalId" => 24_424_930,
               "code" => "zoological",
               "id" => "VP",
               "label" => "Vespoidea",
               "labelHtml" => "Vespoidea",
               "name" => "Vespoidea",
               "namesIndexId" => 24_424_939,
               "namesIndexMatchType" => "exact",
               "parent" => "KZMNP",
               "parentId" => "KZMNP",
               "rank" => "superfamily",
               "status" => "accepted"
             },
             %{
               "canonical" => false,
               "canonicalId" => 70_400,
               "code" => "zoological",
               "id" => "KZMNP",
               "label" => "Aculeata",
               "labelHtml" => "Aculeata",
               "name" => "Aculeata",
               "namesIndexId" => 70_403,
               "namesIndexMatchType" => "exact",
               "parent" => "KZPW7",
               "parentId" => "KZPW7",
               "rank" => "infraorder",
               "status" => "accepted"
             },
             %{
               "canonical" => false,
               "canonicalId" => 1_184_652,
               "code" => "zoological",
               "id" => "KZPW7",
               "label" => "Apocrita",
               "labelHtml" => "Apocrita",
               "name" => "Apocrita",
               "namesIndexId" => 1_184_677,
               "namesIndexMatchType" => "exact",
               "parent" => "HYM",
               "parentId" => "HYM",
               "rank" => "suborder",
               "status" => "accepted"
             },
             %{
               "canonical" => false,
               "canonicalId" => 8_315_447,
               "code" => "zoological",
               "id" => "HYM",
               "label" => "Hymenoptera",
               "labelHtml" => "Hymenoptera",
               "name" => "Hymenoptera",
               "namesIndexId" => 9_726_273,
               "namesIndexMatchType" => "exact",
               "parent" => "H6",
               "parentId" => "H6",
               "rank" => "order",
               "status" => "accepted"
             },
             %{
               "canonical" => false,
               "canonicalId" => 11_244_002,
               "id" => "H6",
               "label" => "Insecta",
               "labelHtml" => "Insecta",
               "name" => "Insecta",
               "namesIndexId" => 11_244_003,
               "namesIndexMatchType" => "exact",
               "parent" => "L2655",
               "parentId" => "L2655",
               "rank" => "class",
               "status" => "accepted"
             },
             %{
               "canonical" => false,
               "canonicalId" => 10_144_387,
               "code" => "zoological",
               "id" => "L2655",
               "label" => "Hexapoda",
               "labelHtml" => "Hexapoda",
               "name" => "Hexapoda",
               "namesIndexId" => 10_144_399,
               "namesIndexMatchType" => "exact",
               "parent" => "RT",
               "parentId" => "RT",
               "rank" => "subphylum",
               "status" => "accepted"
             },
             %{
               "canonical" => false,
               "canonicalId" => 1_325_914,
               "id" => "RT",
               "label" => "Arthropoda",
               "labelHtml" => "Arthropoda",
               "name" => "Arthropoda",
               "namesIndexId" => 1_326_121,
               "namesIndexMatchType" => "exact",
               "parent" => "N",
               "parentId" => "N",
               "rank" => "phylum",
               "status" => "accepted"
             },
             %{
               "canonical" => false,
               "canonicalId" => 605_324,
               "id" => "N",
               "label" => "Animalia",
               "labelHtml" => "Animalia",
               "name" => "Animalia",
               "namesIndexId" => 605_377,
               "namesIndexMatchType" => "exact",
               "parent" => "CS5HF",
               "parentId" => "CS5HF",
               "rank" => "kingdom",
               "status" => "accepted"
             },
             %{
               "authorship" => "(Chatton, 1925) Whittaker & Margulis, 1978",
               "canonical" => false,
               "canonicalId" => 9_856_432,
               "id" => "CS5HF",
               "label" => "Eukaryota (Chatton, 1925) Whittaker & Margulis, 1978",
               "labelHtml" => "Eukaryota (Chatton, 1925) Whittaker & Margulis, 1978",
               "name" => "Eukaryota",
               "namesIndexId" => 9_856_433,
               "namesIndexMatchType" => "exact",
               "rank" => "domain",
               "status" => "accepted"
             }
           ],
           "code" => "zoological",
           "id" => "DY5M",
           "label" => "Anergates atratulus (Schenck, 1852)",
           "labelHtml" => "<i>Anergates atratulus</i> (Schenck, 1852)",
           "name" => "Anergates atratulus",
           "namesIndexId" => 476_311,
           "namesIndexMatchType" => "variant",
           "parent" => "CMV7J",
           "parentId" => "CMV7J",
           "rank" => "species",
           "sectorKey" => 64_431,
           "status" => "synonym"
         }
       },
       trailers: %{},
       private: %{}
     }}
  end
end
