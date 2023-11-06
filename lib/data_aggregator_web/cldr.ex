defmodule DataAggregatorWeb.Cldr do
  @moduledoc false

  use Cldr,
    locales: DataAggregatorWeb.Locale.locales(),
    gettext: DataAggregatorWeb.Gettext,
    otp_app: :data_aggregator,
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime, Cldr.Unit],
    force_locale_download: false,
    generate_docs: true
end
