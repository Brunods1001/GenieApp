module Todos

using SearchLight
using TodoMVC.TodosValidator
import SearchLight.Validation: ModelValidator, ValidationRule

import SearchLight: AbstractModel, DbId
import Base: @kwdef

export Todo

@kwdef mutable struct Todo <: AbstractModel
  id::DbId = DbId()
  todo::String = ""
  completed::Bool = false
end

SearchLight.Validation.validator(::Type{Todo}) = ModelValidator([
  ValidationRule(:todo, TodosValidator.not_empty)
])

end
