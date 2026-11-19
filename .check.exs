[
  tools: [
    {:credo, "mix credo --strict"},
    {:sobelow, "mix sobelow --exit"},
    {:doctor, "mix doctor"},
    {:lint, "mix lint", deps: [:dialyzer, :doctor, :sobelow, :credo]},
    {:ex_doc, false},
    {:gettext, false},
    {:mix_audit, false},
    {:hex_audit, false},
    {:npm_test, false},
    {:usage_rules, false}
  ]
]
