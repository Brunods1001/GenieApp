module TodosController

using TodoMVC.Todos
using TodoMVC.ViewHelper

using Genie.Renderers
using Genie.Renderers.Html
using Genie.Renderers.Json
using Genie.Requests
using Genie.Router

using SearchLight
using SearchLight: count, all
using SearchLight.Validation

function count_todos()
  notdonetodos = count(Todo, completed = false)
  donetodos = count(Todo, completed = true)

  (
      notdonetodos = notdonetodos,
      donetodos = donetodos,
      alltodos = notdonetodos + donetodos,
  )
end

function todos()
  todos = if params(:filter, "") == "done"
      find(Todo, completed = true)
  elseif params(:filter, "") == "notdone"
      find(Todo, completed = false)
  else
      all(
          Todo;
          limit = params(:limit, SearchLight.SQLLimit_ALL) |> SQLLimit,
          offset = (parse(Int, params(:page, "1")) - 1) * parse(Int, params(:limit, "0")),
      )
  end
end

function todos_and_counts()
  # paginated todos
  todos = all(
    Todo; 
    limit = params(:limit, SearchLight.SQLLimit_ALL) 
      |> SQLLimit,
    offset = (
      (parse(Int, params(:page, "1")) - 1 ) * parse(Int, params(:limit, "0"))
    )
  )
  todos = sort(todos, by = x -> x.completed)
  notdonetodos = length(filter(x -> !x.completed, todos))
  donetodos = length(filter(x -> x.completed, todos))
  alltodos = notdonetodos + donetodos
  todos = if params(:filter, "") == "done"
    filter(x -> x.completed, todos)
  elseif params(:filter, "") == "notdone"
    filter(x -> !x.completed, todos)
  else
    todos
  end
  (
    todos, 
    (notdonetodos, donetodos, alltodos)
  )
end

function index()
  # get error or success params
  todos, (notdonetodos, donetodos, alltodos) = todos_and_counts()
  html(
    :todos, :index;
    notdonetodos, donetodos, alltodos, 
    ViewHelper.active,
    todos=todos
  )
end

"Creates a Todo from _form.jl.html params"
function create()
  todo = Todo(todo = params(:todo))
  validator = validate(todo)
  if haserrors(validator)
    return redirect("/?error=$(errors_to_string(validator))")
  end
  if save(todo)
    redirect("/?success=Created a todo item")
  else
    redirect("/?error=Could not create a todo item")
  end
end

"Updates a Todo and returns JSON when completed"
function toggle()
  todo = findone(Todo, id = params(:id))
  if todo === nothing
    return Router.error(NOT_FOUND, "Todo item with id $(params(:id))", MIME"text/html")
  end
  todo.completed = !todo.completed
  validator = validate(todo)
  haserrors(validator) || save(todo) && json(:todo => todo)
end

"Updates a Todo and returns JSON when completed"
function update()
  todo = findone(Todo, id = params(:id))
  if todo === nothing
    return Router.error(NOT_FOUND, "Todo item with id $(params(:id))", MIME"text/html")
  end
  todo.todo = replace(jsonpayload("todo"), "<br>"=>"")
  validator = validate(todo)
  haserrors(validator) || save(todo) && json(:todo => todo)
end

"Deletes a Todo and returns JSON when completed"
function delete()
  todo = findone(Todo, id = params(:id))
  if todo === nothing
    return Router.error(NOT_FOUND, "Todo item with id $(params(:id))", MIME"text/html")
  end
  SearchLight.delete(todo) 
  json(Dict(:id => (:value => params(:id))))
end


### API

module API
module V1

using TodoMVC.Todos
using Genie.Router
using Genie.Renderers.Json
using ....TodosController
using Genie.Requests
using SearchLight.Validation
using SearchLight

function check_payload(payload = Requests.jsonpayload())
    isnothing(payload) && throw(
        JSONException(status = BAD_REQUEST, message = "Invalid JSON message received"),
    )
    payload
end

function persist(todo)
    validator = validate(todo)
    if haserrors(validator)
        return JSONException(status = BAD_REQUEST, message = errors_to_string(validator)) |>
               json
    end

    try
        if ispersisted(todo)
            save!(todo)
            json(todo, status = OK)
        else
            save!(todo)
            json(
                todo,
                status = CREATED,
                headers = Dict("Location" => "/api/v1/todos/$(todo.id)"),
            )
        end
    catch ex
        JSONException(status = INTERNAL_ERROR, message = string(ex)) |> json
    end
end

function create()
    payload = try
        check_payload()
    catch ex
        return json(ex)
    end

    todo =
        Todo(todo = get(payload, "todo", ""), completed = get(payload, "completed", false))
    persist(todo)
end

function list()
    TodosController.todos() |> json
end

function item()
    todo = findone(Todo, id = params(:id))
    if todo === nothing
        return JSONException(status = NOT_FOUND, message = "Todo not found") |> json
    end

    todo |> json
end

function update()
    payload = try
        check_payload()
    catch ex
        return json(ex)
    end

    todo = findone(Todo, id = params(:id))
    if todo === nothing
        return JSONException(status = NOT_FOUND, message = "Todo not found") |> json
    end

    todo.todo = get(payload, "todo", todo.todo)
    todo.completed = get(payload, "completed", todo.completed)

    persist(todo)
end

function delete()
    todo = findone(Todo, id = params(:id))
    if todo === nothing
        return JSONException(status = NOT_FOUND, message = "Todo not found") |> json
    end

    try
        SearchLight.delete(todo) |> json
    catch ex
        JSONException(status = INTERNAL_ERROR, message = string(ex)) |> json
    end
end

end # V1
end # API

end
