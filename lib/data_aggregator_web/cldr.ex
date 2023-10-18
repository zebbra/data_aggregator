defmodule DataAggregatorWeb.Cldr do
  use Cldr,
    locales: DataAggregatorWeb.Locale.locales(),
    gettext: DataAggregatorWeb.Gettext,
    otp_app: :data_aggregator,
    providers: [Cldr.Number, Cldr.LocaleDisplay, Cldr.Calendar, Cldr.DateTime, Cldr.Unit],
    force_locale_download: false
end
