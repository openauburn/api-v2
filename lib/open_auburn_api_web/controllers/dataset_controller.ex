defmodule OpenAuburnApiWeb.DatasetController do
  use OpenAuburnApiWeb, :controller
  # alias OpenAuburnApi.{Datasets.Dataset}
  import Plug.Conn

  @optional_params %{"page" => 1, "page_size" => 10}
  def index(conn, params) do
    table_name = conn.params["table_name"]

    params = Map.merge(@optional_params, params)
    page = params |> Map.get("page", 1)
    page_size = params |> Map.get("page_size", 1)

    {page_i, _} = :string.to_integer(to_charlist(page))
    {page_size_i, _} = :string.to_integer(to_charlist(page_size))
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

    data =
      result.rows
      |> Enum.map(fn row ->
        Enum.zip(result.columns, row) |> Map.new()
      end)

    json = Jason.encode!(data)

    conn
    |> put_status(200)
    |> put_resp_content_type("application/json")
    |> text(json)
  end

  def show(conn, %{"id" => id}) do
    table_name = conn.params["table_name"]
    sql = "SELECT * FROM #{table_name} WHERE id=#{id}"
    {:ok, result} = Ecto.Adapters.SQL.query(OpenAuburnApi.Repo, sql)

    data =
      result.rows
      |> Enum.map(fn row ->
        Enum.zip(result.columns, row) |> Map.new()
      end)

    json = Jason.encode!(data)

    conn
    |> put_status(200)
    |> put_resp_content_type("application/json")
    |> text(json)
  end

  def create(conn, %{"table_name" => table_name, "key" => key}) do
    if(key == System.fetch_env!("AUTH_PASSWORD")) do
      {:ok, result} =
        Ecto.Adapters.SQL.query(OpenAuburnApi.Repo, "SELECT * FROM #{table_name} WHERE false")

      object = conn.body_params
      input_fields = Map.keys(object)
      fields = result.columns
      fields = List.delete(fields, "id")

      if Enum.sort(fields) == Enum.sort(input_fields) do
        n = object |> Map.values() |> length()
        params = Enum.map(1..n, &"$#{&1}")
        placeholders = Enum.join(params, ", ")

        sql =
          "INSERT INTO #{table_name} " <>
            "(#{Enum.join(object |> Map.keys(), ",")}) " <>
            "VALUES (#{placeholders})"

        Ecto.Adapters.SQL.query!(OpenAuburnApi.Repo, sql, Map.values(object))

        conn |> put_status(200) |> json(%{message: "Record inserted successfully."})
      else
      end
    else
      conn |> put_status(401) |> json(%{message: "Unauthorized."})
    end
  end
end
