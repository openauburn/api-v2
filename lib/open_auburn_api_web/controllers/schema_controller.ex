defmodule OpenAuburnApiWeb.SchemaController do
  use OpenAuburnApiWeb, :controller
  import Plug.Conn

  @optional_params %{"page" => 1, "page_size" => 10}
  def index(conn, params) do
    params = Map.merge(@optional_params, params)
    page = params |> Map.get("page", 1)
    page_size = params |> Map.get("page_size", 1)

    {page_i, _} = :string.to_integer(to_charlist(page))
    {page_size_i, _} = :string.to_integer(to_charlist(page_size))

    offset = (page_i - 1) * page_size_i
    limit = page_size_i

    sql = """
    SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name!='schema_migrations'
    OFFSET $1
    LIMIT $2
    """

    {:ok, result} = Ecto.Adapters.SQL.query(OpenAuburnApi.Repo, sql, [offset, limit])

    tables =
      result.rows
      |> Enum.map(fn row ->
        Enum.zip(result.columns, row) |> Map.new()
      end)

    schemas =
      tables
      |> Enum.map(fn table ->
        get_schema(table["table_name"])
      end)
      |> Enum.into([])

    IO.inspect(schemas)

    json = Jason.encode!(schemas)

    conn
    |> put_status(200)
    |> put_resp_content_type("application/json")
    |> text(json)
  end

  def show(conn, %{"table_name" => table_name}) do
    data = get_schema(table_name)

    json = Jason.encode!(data)

    conn
    |> put_status(200)
    |> put_resp_content_type("application/json")
    |> text(json)
  end

  defp get_schema(table_name) do
    sql = "SELECT
    c.column_name,
    c.data_type,
    c.is_nullable,
    pgd.description
FROM
    information_schema.columns c
LEFT JOIN
    pg_catalog.pg_description pgd ON (pgd.objsubid = c.ordinal_position AND pgd.objoid = (SELECT oid FROM pg_catalog.pg_class WHERE relname = c.table_name AND relnamespace = (SELECT oid FROM pg_catalog.pg_namespace WHERE nspname = c.table_schema)))
WHERE
    c.table_name = '#{table_name}';;
  "

    {:ok, result} = Ecto.Adapters.SQL.query(OpenAuburnApi.Repo, sql)

    data =
      result.rows
      |> Enum.map(fn row ->
        Enum.zip(result.columns, row) |> Map.new()
      end)

    data = %{
      "table_name" => table_name,
      "fields" => data
    }

    data
  end
end

#   def create(conn, %{"table_name" => table_name, "key" => key}) do
#     if(key == System.fetch_env!("AUTH_PASSWORD")) do
#       {:ok, result} =
#         Ecto.Adapters.SQL.query(OpenAuburnApi.Repo, "SELECT * FROM #{table_name} WHERE false")

#       object = conn.body_params
#       input_fields = Map.keys(object)
#       fields = result.columns
#       fields = List.delete(fields, "id")

#       if Enum.sort(fields) == Enum.sort(input_fields) do
#         n = object |> Map.values() |> length()
#         params = Enum.map(1..n, &"$#{&1}")
#         placeholders = Enum.join(params, ", ")

#         sql =
#           "INSERT INTO #{table_name} " <>
#             "(#{Enum.join(object |> Map.keys(), ",")}) " <>
#             "VALUES (#{placeholders})"

#         Ecto.Adapters.SQL.query!(OpenAuburnApi.Repo, sql, Map.values(object))

#         conn |> put_status(200) |> json(%{message: "Record inserted successfully."})
#       else
#       end
#     else
#       conn |> put_status(401) |> json(%{message: "Unauthorized."})
#     end
#   end
# end
