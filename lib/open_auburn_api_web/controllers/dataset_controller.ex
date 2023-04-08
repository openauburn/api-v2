defmodule OpenAuburnApiWeb.DatasetController do
  use OpenAuburnApiWeb, :controller
  import Plug.Conn

  @optional_params %{"page" => 1, "page_size" => 10}
  def index(conn, params) do
    table_name = conn.params["table_name"]

    params = Map.merge(@optional_params, params)
    # page = conn.params["page"] || 1
    # page_size = conn.params["page_size"] || 10

      # Ensure that page and page_size are integers
    page = params |> Map.get("page", 1)
    page_size = params |> Map.get("page_size", 1)

    {page_i, _} = :string.to_integer(to_charlist(page))
    {page_size_i, _} = :string.to_integer(to_charlist(page_size))
    # query = from t in table_name, select: t.*
    from_clause = "FROM #{table_name}"
    select_clause = "SELECT *"

    offset = (page_i - 1) * page_size_i
    limit = page_size_i

    sql = """
    #{select_clause}
    #{from_clause}
    OFFSET $1
    LIMIT $2
    """

    {:ok, result} = Ecto.Adapters.SQL.query(OpenAuburnApi.Repo, sql, [offset, limit])
    # IO.puts(data)# query = from(Helpers.table(table_name), select: [:*])
    # data = OpenAuburnApi.Repo.all(query)

    data = result.rows |> Enum.map(fn row ->
      Enum.zip(result.columns, row) |> Map.new()
    end)

    json = Jason.encode!(data)

    conn
    |> put_status(200)
    |> put_resp_content_type("application/json")
    |> text(json)
    # conn
    # # |> put_status(200)
    # # |> json(data)
  end

  # defp from(table) do
  #   Ecto.Query.from(t in fragment(table), select: fragment("t.*"))
  # end

end
