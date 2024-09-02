
# Script for populating the database. You can run it as:
#
#     mix run priv/repo/catalogs/init.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     DataAggregator.Repo.insert!(%DataAggregator.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias DataAggregator.Accounts.UserImporter

"initialize/users/users.csv"
|> Path.expand(DataAggregator.priv_dir())
|> Path.wildcard()
|> Enum.each(&UserImporter.import_users_from_csv/1)
