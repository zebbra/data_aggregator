defmodule DataAggregator.Transition.Registry do
  use Ash.Registry,
    extensions: [
      # This extension adds helpful compile time validations
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry DataAggregator.Transition.Annotation
    entry DataAggregator.Transition.EncodingChangeEvent
    entry DataAggregator.Transition.ChangeEvent
    entry DataAggregator.Transition.Run
  end
end
