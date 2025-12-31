defmodule DataAggregator.IUCN.RestAPIStub do
  @moduledoc """
  Module to interact with the IUCN Redlist Rest API in tests. Subs the real RestAPI module, so no api requests will be made.

  Note while stubbing:

      note for anyone facing the issue of having his/her stub/expect not called:
      make sure that the function you are stubbing/expecting is called NOT within the
      same module the function is declared!

      clean design helps: move stubable functions and api clients to a separate modules

      https://github.com/edgurgel/mimic/issues/27

  """

  alias DataAggregator.Types.Api

  @spec get_iucn_redlist_category(String.t(), String.t()) :: Api.response()
  def get_iucn_redlist_category(genus \\ "Anergates", specific_epithet \\ "atratulus")

  def get_iucn_redlist_category("something_unknown", "something_unknown") do
    {:ok,
     %Req.Response{
       status: 404,
       headers: %{},
       body: %{
         "error" => "Not found"
       },
       trailers: %{},
       private: %{}
     }}
  end

  def get_iucn_redlist_category(_genus, _specific_epithet) do
    {:ok,
     %Req.Response{
       status: 200,
       headers: %{},
       body: %{
         "assessments" => [
           %{
             "assessment_id" => 3_390_729,
             "latest" => true,
             "possibly_extinct" => false,
             "possibly_extinct_in_the_wild" => false,
             "red_list_category_code" => "VU",
             "scopes" => [%{"code" => "1", "description" => %{"en" => "Global"}}],
             "sis_taxon_id" => 1285,
             "taxon_scientific_name" => "Anergates atratulus",
             "url" => "https://www.iucnredlist.org/species/1285/3390729",
             "year_published" => "1996"
           },
           %{
             "assessment_id" => 3_390_790,
             "latest" => false,
             "possibly_extinct" => false,
             "possibly_extinct_in_the_wild" => false,
             "red_list_category_code" => "I",
             "scopes" => [%{"code" => "1", "description" => %{"en" => "Global"}}],
             "sis_taxon_id" => 1285,
             "taxon_scientific_name" => "Anergates atratulus",
             "url" => "https://www.iucnredlist.org/species/1285/3390790",
             "year_published" => "1990"
           },
           %{
             "assessment_id" => 3_390_695,
             "latest" => false,
             "possibly_extinct" => false,
             "possibly_extinct_in_the_wild" => false,
             "red_list_category_code" => "I",
             "scopes" => [%{"code" => "1", "description" => %{"en" => "Global"}}],
             "sis_taxon_id" => 1285,
             "taxon_scientific_name" => "Anergates atratulus",
             "url" => "https://www.iucnredlist.org/species/1285/3390695",
             "year_published" => "1988"
           },
           %{
             "assessment_id" => 3_390_712,
             "latest" => false,
             "possibly_extinct" => false,
             "possibly_extinct_in_the_wild" => false,
             "red_list_category_code" => "I",
             "scopes" => [%{"code" => "1", "description" => %{"en" => "Global"}}],
             "sis_taxon_id" => 1285,
             "taxon_scientific_name" => "Anergates atratulus",
             "url" => "https://www.iucnredlist.org/species/1285/3390712",
             "year_published" => "1986"
           }
         ],
         "params" => %{"genus_name" => "Anergates", "species_name" => "atratulus"},
         "taxon" => %{
           "authority" => "(Schenck, 1852)",
           "class_name" => "INSECTA",
           "common_names" => [],
           "family_name" => "FORMICIDAE",
           "genus_name" => "Anergates",
           "infra_name" => nil,
           "infrarank" => false,
           "infrarank_taxa" => [],
           "kingdom_name" => "ANIMALIA",
           "order_name" => "HYMENOPTERA",
           "phylum_name" => "ARTHROPODA",
           "scientific_name" => "Anergates atratulus",
           "sis_id" => 1285,
           "species" => true,
           "species_name" => "atratulus",
           "species_taxa" => [],
           "ssc_groups" => [
             %{
               "description" => "Red List Authority Coordinator: Gabrielle (Gabby) Flinn",
               "name" => "IUCN SSC Ant Specialist Group",
               "url" => nil
             }
           ],
           "subpopulation" => false,
           "subpopulation_name" => nil,
           "subpopulation_taxa" => [],
           "synonyms" => []
         }
       },
       trailers: %{},
       private: %{}
     }}
  end
end
