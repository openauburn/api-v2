defmodule OpenAuburnApiWeb.DatasetController do
  use OpenAuburnApiWeb, :controller
  # alias OpenAuburnApi.{Datasets.Dataset}
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

    metadata =
      tables
      |> Enum.map(fn table ->
        get_metadata(table["table_name"])
      end)

    json = Jason.encode!(metadata)

    conn
    |> put_status(200)
    |> put_resp_content_type("application/json")
    |> text(json)
  end

  def get_metadata(table_name) do
    sql = "WITH table_stats AS (
  SELECT
    pg_relation_size('#{table_name}') AS size,
    COUNT(*) AS count,
    (SELECT pg_xact_commit_timestamp(t.xmin) AS modified_ts
     FROM #{table_name} t
     ORDER BY modified_ts DESC NULLS LAST
     LIMIT 1) AS last_modified
  FROM #{table_name}
)
SELECT * FROM table_stats;"

    {:ok, result} = Ecto.Adapters.SQL.query(OpenAuburnApi.Repo, sql)

    row = result.rows |> List.first()
    data = Enum.zip(result.columns, row) |> Map.new()

    static_pairs = [
      {:schema_url, "https://api.v1.openauburn.org/schemas/#{table_name}"},
      {:api_url, "https://api.v1.openauburn.org/datasets/#{table_name}"},
      {:title, table_name}
    ]

    data = Map.merge(data, Map.new(static_pairs))
    data = Map.put(data, :title, table_name)
    data
  end

  @optional_params %{"page" => 1, "page_size" => 10}
  def dataset(conn, params) do
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

  def record(conn, %{"id" => id}) do
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

  def add_record(conn, %{"table_name" => table_name, "key" => key}) do
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
