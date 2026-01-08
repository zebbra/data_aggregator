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
  def parse_name(_unparsed_scientific_name \\ "Anergates atratulus (Schenck, 1852)") do
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
  def lookup_species_by_name(_scientific_name \\ "Anergates atratulus") do
    {:ok,
     %Req.Response{
       status: 200,
       headers: %{
         "accept-ranges" => ["bytes"],
         "age" => ["114"],
         "cache-control" => ["public, max-age=604800, s-maxage=604800"],
         "content-type" => ["application/json"],
         "date" => ["Fri, 19 Dec 2025 10:23:25 GMT"],
         "vary" => ["Cookie, Accept, Accept-Encoding, Accept-Language, User-Agent", "Origin"],
         "via" => [
           "HTTP/1.1 git.gammaspectra.live/git/go-away@v0.0.0-20250904213329-95ac08540b8c+dirty",
           "1.1 varnish (Varnish/7.1)"
         ],
         "x-backend" => ["api"],
         "x-cache" => ["hit_cached"],
         "x-varnish" => ["971000238 977314260"]
       },
       body: %{
         "empty" => false,
         "last" => true,
         "limit" => 1,
         "offset" => 0,
         "result" => [
           %{
             "classification" => [
               %{
                 "id" => "CS5HF",
                 "label" => "Eukaryota",
                 "labelHtml" => "Eukaryota",
                 "name" => "Eukaryota",
                 "rank" => "domain"
               },
               %{
                 "id" => "N",
                 "label" => "Animalia",
                 "labelHtml" => "Animalia",
                 "name" => "Animalia",
                 "rank" => "kingdom"
               },
               %{
                 "id" => "RT",
                 "label" => "Arthropoda",
                 "labelHtml" => "Arthropoda",
                 "name" => "Arthropoda",
                 "rank" => "phylum"
               },
               %{
                 "id" => "L2655",
                 "label" => "Hexapoda",
                 "labelHtml" => "Hexapoda",
                 "name" => "Hexapoda",
                 "rank" => "subphylum"
               },
               %{
                 "id" => "H6",
                 "label" => "Insecta",
                 "labelHtml" => "Insecta",
                 "name" => "Insecta",
                 "rank" => "class"
               },
               %{
                 "id" => "HYM",
                 "label" => "Hymenoptera",
                 "labelHtml" => "Hymenoptera",
                 "name" => "Hymenoptera",
                 "rank" => "order"
               },
               %{
                 "id" => "KZPW7",
                 "label" => "Apocrita",
                 "labelHtml" => "Apocrita",
                 "name" => "Apocrita",
                 "rank" => "suborder"
               },
               %{
                 "id" => "KZMNP",
                 "label" => "Aculeata",
                 "labelHtml" => "Aculeata",
                 "name" => "Aculeata",
                 "rank" => "infraorder"
               },
               %{
                 "id" => "VP",
                 "label" => "Vespoidea",
                 "labelHtml" => "Vespoidea",
                 "name" => "Vespoidea",
                 "rank" => "superfamily"
               },
               %{
                 "id" => "CLRKP",
                 "label" => "Formicidae",
                 "labelHtml" => "Formicidae",
                 "name" => "Formicidae",
                 "rank" => "family"
               },
               %{
                 "id" => "CMD7Z",
                 "label" => "Myrmicinae",
                 "labelHtml" => "Myrmicinae",
                 "name" => "Myrmicinae",
                 "rank" => "subfamily"
               },
               %{
                 "id" => "CLMZ7",
                 "label" => "Crematogastrini",
                 "labelHtml" => "Crematogastrini",
                 "name" => "Crematogastrini",
                 "rank" => "tribe"
               },
               %{
                 "id" => "63V54",
                 "label" => "Tetramorium",
                 "labelHtml" => "<i>Tetramorium</i>",
                 "name" => "Tetramorium",
                 "rank" => "genus"
               },
               %{
                 "id" => "CMV7J",
                 "label" => "Tetramorium atratulum",
                 "labelHtml" => "<i>Tetramorium atratulum</i>",
                 "name" => "Tetramorium atratulum",
                 "rank" => "species"
               },
               %{
                 "id" => "DY5M",
                 "label" => "Anergates atratulus",
                 "labelHtml" => "<i>Anergates atratulus</i>",
                 "name" => "Anergates atratulus",
                 "rank" => "species"
               }
             ],
             "group" => "hymenoptera",
             "id" => "DY5M",
             "sectorDatasetKey" => 54_937,
             "usage" => %{
               "accepted" => %{
                 "created" => "2025-11-10T13:47:46.72509",
                 "createdBy" => 102,
                 "datasetKey" => 313_100,
                 "extinct" => false,
                 "id" => "CMV7J",
                 "label" => "Tetramorium atratulum (Schenck, 1852)",
                 "labelHtml" => "<i>Tetramorium atratulum</i> (Schenck, 1852)",
                 "link" => "https://antcat.org/catalog/430775",
                 "merged" => false,
                 "modified" => "2025-11-10T13:47:46.72509",
                 "modifiedBy" => 102,
                 "name" => %{
                   "authorship" => "(Schenck, 1852)",
                   "basionymAuthorship" => %{
                     "authors" => ["Schenck"],
                     "year" => "1852"
                   },
                   "basionymOrCombinationAuthorship" => %{
                     "authors" => ["Schenck"],
                     "year" => "1852"
                   },
                   "code" => "zoological",
                   "created" => "2025-11-10T13:47:46.72509",
                   "createdBy" => 102,
                   "datasetKey" => 313_100,
                   "genus" => "Tetramorium",
                   "id" => "MguwnX5MWvQH2hAy16de-1",
                   "link" => "https://antcat.org/catalog/430775",
                   "merged" => false,
                   "modified" => "2025-11-10T13:47:46.72509",
                   "modifiedBy" => 102,
                   "namesIndexId" => 22_231_881,
                   "namesIndexType" => "exact",
                   "nomStatus" => "established",
                   "origin" => "source",
                   "parsed" => true,
                   "publishedInId" => "8b6357fd-9ccd-4159-9b37-bb24dd2f9fc7",
                   "rank" => "species",
                   "scientificName" => "Tetramorium atratulum",
                   "sectorKey" => 64_431,
                   "specificEpithet" => "atratulum",
                   "type" => "scientific",
                   "verbatimSourceKey" => 297_102_011
                 },
                 "origin" => "source",
                 "parentId" => "63V54",
                 "remarks" =>
                   "Myrmica atratula [Schenck, 1852](https://antcat.org/references/128471) [PDF](https://antcat.org/documents/2672/2544.pdf): 91 (q.m.) GERMANY. Palearctic. Primary type information: Primary type material: syntype queen(s), syntype male(s) (numbers not stated). Primary type locality: Germany: Nassau Distr., NW Frankfurt, 24.vi.(1851?), 1.vii.(1851?) (P.A. Schenck). Primary type depository: SMFM (perhaps also UMPU). Type notes: Schenck’s Hymenoptera specimens originally in UMPU ([Horn & Kahle, 1936](https://antcat.org/references/143791): 242); later transferred to SMFM. [AntCat](https://www.antcat.org/catalog/430775) [AntWiki](https://www.antwiki.org/wiki/Tetramorium_atratulum)Taxonomic history[Also described as new by [Schenck, 1853b](https://antcat.org/references/128477) [PDF](https://antcat.org/documents/2673/2545.pdf): 186.][Misspelled as atrata by [Taschenberg, 1880](https://antcat.org/references/144408): 259, 705][Misspelled as atradulus by [Gösswald, 1932](https://antcat.org/references/125557) [PDF](https://antcat.org/documents/6867/Gösswald__K._1932.pdf): 83.][Wheeler, 1909g](https://antcat.org/references/130041) [PDF](https://antcat.org/documents/3448/10560.pdf): 182 (l.); [Borowiec & Salata, 2025a](https://antcat.org/references/144454) [PDF](https://antcat.org/documents/8758/monograph-of-greek-ants-volume-2-part-1-text_final-after-review-1.pdf): 15 (em.)Combination in [Tetramorium](https://www.antcat.org/catalog/429802): [Mayr, 1855](https://antcat.org/references/127185) [PDF](https://antcat.org/documents/2121/4443.pdf): 429.Combination in [Tomognathus](https://www.antcat.org/catalog/429928): [Mayr, 1863a](https://antcat.org/references/127213) [PDF](https://antcat.org/documents/2141/4446.pdf): 457.Combination in [Anergates](https://www.antcat.org/catalog/429793): [Forel, 1874](https://antcat.org/references/124988) [PDF](https://antcat.org/documents/1303/3910.pdf): 68.Combination in [Tetramorium](https://www.antcat.org/catalog/429802): [Ward et al., 2015](https://antcat.org/references/142630) [10.1111/syen.12090](https://doi.org/10.1111/syen.12090) [PDF](https://antcat.org/documents/6341/ward_et_al_2015_syst_entomol_myrmicine_phylogeny_incl_supp_info.pdf): 76.Junior synonym of [Tetramorium caespitum](https://www.antcat.org/catalog/450200): [Mayr, 1861](https://antcat.org/references/127189) [PDF](https://antcat.org/documents/2123/8104.pdf): 61 (in key); [Mayr, 1865](https://antcat.org/references/127193) [PDF](https://antcat.org/documents/6498/mayr__g-_1865-_formicidae-_in___reise_der_osterreichischen_fregatte_-novara-_um_die_erde_in_den_jahren_1857__1858__1859-_zoologischer_theil-_bd-_ii-_abt-_1.pdf): 89; [Dours, 1873](https://antcat.org/references/124387) [PDF](https://antcat.org/documents/1025/14701.pdf): 168; [André, 1874c](https://antcat.org/references/142477): 203 (in list); [Dalla Torre, 1893](https://antcat.org/references/124002) [PDF](https://antcat.org/documents/838/7602.pdf): 132.Status as species: [Mayr, 1855](https://antcat.org/references/127185) [PDF](https://antcat.org/documents/2121/4443.pdf): 429 (redescription); [Smith, 1858a](https://antcat.org/references/128685) [PDF](https://antcat.org/documents/2734/8127.pdf): 117; [Mayr, 1863a](https://antcat.org/references/127213) [PDF](https://antcat.org/documents/2141/4446.pdf): 457; [Forel, 1874](https://antcat.org/references/124988) [PDF](https://antcat.org/documents/1303/3910.pdf): 93 (redescription); [Emery & Forel, 1879](https://antcat.org/references/124778) [PDF](https://antcat.org/documents/7990/emery_forel_1879_mitt-_sch-_ent-_ges-_catalogue_des_formicides_d-europe.pdf): 457; [André, 1882d](https://antcat.org/references/124525) [PDF](https://antcat.org/documents/6070/andre_1882.pdf): 278 (in key); [Lameere, 1892](https://antcat.org/references/126777): 67; [Dalla Torre, 1893](https://antcat.org/references/124002) [PDF](https://antcat.org/documents/838/7602.pdf): 64; [Wasmann, 1894](https://antcat.org/references/129627): 165; [Wheeler, 1901e](https://antcat.org/references/129964) [PDF](https://antcat.org/documents/3382/10490.pdf): 717; [Ruzsky, 1905b](ht...",
                 "sectorKey" => 64_431,
                 "status" => "accepted",
                 "verbatimSourceKey" => 297_102_011
               },
               "created" => "2025-11-10T13:49:16.504784",
               "createdBy" => 102,
               "datasetKey" => 313_100,
               "id" => "DY5M",
               "identifier" => ["tsn:578332"],
               "label" => "Anergates atratulus (Schenck, 1852)",
               "labelHtml" => "<i>Anergates atratulus</i> (Schenck, 1852)",
               "merged" => false,
               "modified" => "2025-11-10T13:49:16.504784",
               "modifiedBy" => 102,
               "name" => %{
                 "authorship" => "(Schenck, 1852)",
                 "basionymAuthorship" => %{
                   "authors" => ["Schenck"],
                   "year" => "1852"
                 },
                 "basionymOrCombinationAuthorship" => %{
                   "authors" => ["Schenck"],
                   "year" => "1852"
                 },
                 "code" => "zoological",
                 "created" => "2025-11-10T13:49:16.504784",
                 "createdBy" => 102,
                 "datasetKey" => 313_100,
                 "genus" => "Anergates",
                 "id" => "kxJmGjuZ6981DOVV7Ecs02",
                 "link" => "https://antcat.org/catalog/495878",
                 "merged" => false,
                 "modified" => "2025-11-10T13:49:16.504784",
                 "modifiedBy" => 102,
                 "nomStatus" => "not established",
                 "origin" => "source",
                 "parsed" => true,
                 "publishedInId" => "8b6357fd-9ccd-4159-9b37-bb24dd2f9fc7",
                 "rank" => "species",
                 "remarks" => "not established",
                 "scientificName" => "Anergates atratulus",
                 "sectorKey" => 64_431,
                 "specificEpithet" => "atratulus",
                 "type" => "scientific",
                 "verbatimSourceKey" => 297_117_396
               },
               "origin" => "source",
               "parentId" => "CMV7J",
               "remarks" =>
                 "obsolete combination. Myrmica atratula [Schenck, 1852](https://antcat.org/references/128471) [PDF](https://antcat.org/documents/2672/2544.pdf): 91 (q.m.) GERMANY. Palearctic. Primary type information: Primary type material: syntype queen(s), syntype male(s) (numbers not stated). Primary type locality: Germany: Nassau Distr., NW Frankfurt, 24.vi.(1851?), 1.vii.(1851?) (P.A. Schenck). Primary type depository: SMFM (perhaps also UMPU). Type notes: Schenck’s Hymenoptera specimens originally in UMPU ([Horn & Kahle, 1936](https://antcat.org/references/143791): 242); later transferred to SMFM. [AntCat](https://www.antcat.org/catalog/495878) [AntWiki](https://www.antwiki.org/wiki/Anergates_atratulus).",
               "sectorKey" => 64_431,
               "status" => "synonym",
               "verbatimSourceKey" => 297_117_396
             }
           }
         ],
         "total" => 1
       },
       trailers: %{},
       private: %{}
     }}
  end
end
