defmodule AppPlanner.Planner do
  @moduledoc """
  The Planner context.
  """

  import Ecto.Query, warn: false
  alias AppPlanner.Repo

  alias AppPlanner.Planner.App
  alias AppPlanner.Planner.AppMember
  alias AppPlanner.Planner.Category
  alias AppPlanner.Planner.Label

  # Categories
  def list_categories do
    Category |> order_by([c], asc: c.name) |> Repo.all()
  end

  def ensure_category_by_name(name) when is_binary(name) do
    name = String.trim(name)
    if name == "", do: nil, else: Repo.get_by(Category, name: name) || create_category!(name)
  end

  defp create_category!(name) do
    %Category{} |> Category.changeset(%{name: name}) |> Repo.insert!()
  end

  @doc """
  Returns the list of apps.

  ## Examples

      iex> list_apps()
      [%App{}, ...]

  """
  def list_apps(user) do
    member_app_ids =
      AppMember
      |> where([m], m.user_id == ^user.id)
      |> select([m], m.app_id)

    App
    |> where([a],
      a.user_id == ^user.id or
        fragment("lower(?)", a.visibility) == "public" or
        a.id in subquery(member_app_ids)
    )
    |> order_by([a], desc: a.inserted_at)
    |> Repo.all()
    |> Repo.preload([:user, :labels, :features, :children, :last_updated_by, likes: [:user], app_members: [:user]])
  end

  @doc """
  Gets a single app.

  Raises `Ecto.NoResultsError` if the App does not exist.

  ## Examples

      iex> get_app!(123)
      %App{}

      iex> get_app!(456)
      ** (Ecto.NoResultsError)

  """
  def get_app!(id, user) when is_binary(id) do
    get_app!(String.to_integer(id), user)
  end

  def get_app!(id, user) when is_integer(id) do
    member_app_ids =
      AppMember
      |> where([m], m.user_id == ^user.id)
      |> select([m], m.app_id)

    App
    |> where([a],
      a.id == ^id and
        (a.user_id == ^user.id or
           fragment("lower(?)", a.visibility) == "public" or a.id in subquery(member_app_ids))
    )
    |> Repo.one!()
    |> Repo.preload([:features, :parent_app, :labels, :user, :last_updated_by, likes: [:user], app_members: [:user], children: [:labels], features: [:last_updated_by]])
  end

  @doc """
  Creates a app.

  ## Examples

      iex> create_app(%{field: value})
      {:ok, %App{}}

      iex> create_app(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_app(attrs, user, labels \\ []) do
    attrs =
      attrs
      |> Map.put("user_id", user.id)
      |> Map.put("last_updated_by_id", user.id)
    %App{}
    |> App.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:labels, labels)
    |> Repo.insert()
  end

  @doc """
  Updates a app.

  ## Examples

      iex> update_app(app, %{field: new_value})
      {:ok, %App{}}

      iex> update_app(app, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_app(%App{} = app, attrs, labels \\ nil, updated_by \\ nil) do
    attrs = if updated_by, do: Map.put(attrs, "last_updated_by_id", updated_by.id), else: attrs
    changeset = App.changeset(app, attrs)

    changeset =
      if labels do
        Ecto.Changeset.put_assoc(changeset, :labels, labels)
      else
        changeset
      end

    Repo.update(changeset)
  end

  @doc """
  Deletes a app.

  ## Examples

      iex> delete_app(app)
      {:ok, %App{}}

      iex> delete_app(app)
      {:error, %Ecto.Changeset{}}

  """
  def delete_app(%App{} = app) do
    Repo.delete(app)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking app changes.

  ## Examples

      iex> change_app(app)
      %Ecto.Changeset{data: %App{}}

  """
  def change_app(%App{} = app, attrs \\ %{}) do
    App.changeset(app, attrs)
  end

  alias AppPlanner.Planner.Feature

  @doc """
  Returns the list of features.

  ## Examples

      iex> list_features()
      [%Feature{}, ...]

  """
  def list_features(user) do
    app_ids = list_apps(user) |> Enum.map(& &1.id)
    Feature
    |> where([f], f.app_id in ^app_ids)
    |> order_by([f], desc: f.updated_at)
    |> Repo.all()
    |> Repo.preload([:app, :last_updated_by])
  end

  @doc """
  Gets a single feature.

  Raises `Ecto.NoResultsError` if the Feature does not exist.

  ## Examples

      iex> get_feature!(123)
      %Feature{}

      iex> get_feature!(456)
      ** (Ecto.NoResultsError)

  """
  def get_feature!(id, user) do
    member_app_ids =
      AppMember
      |> where([m], m.user_id == ^user.id)
      |> select([m], m.app_id)

    Feature
    |> join(:inner, [f], a in App, on: f.app_id == a.id)
    |> where([f, a],
      f.id == ^id and
        (f.user_id == ^user.id or a.user_id == ^user.id or a.id in subquery(member_app_ids))
    )
    |> select([f, _], f)
    |> Repo.one!()
    |> Repo.preload([:app, :last_updated_by])
  end

  @doc """
  Creates a feature.

  ## Examples

      iex> create_feature(%{field: value})
      {:ok, %Feature{}}

      iex> create_feature(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_feature(attrs, user) do
    attrs =
      attrs
      |> Map.put("user_id", user.id)
      |> Map.put("last_updated_by_id", user.id)
    %Feature{}
    |> Feature.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a feature.

  ## Examples

      iex> update_feature(feature, %{field: new_value})
      {:ok, %Feature{}}

      iex> update_feature(feature, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_feature(%Feature{} = feature, attrs, updated_by \\ nil) do
    attrs = if updated_by, do: Map.put(attrs, "last_updated_by_id", updated_by.id), else: attrs
    feature
    |> Feature.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a feature.

  ## Examples

      iex> delete_feature(feature)
      {:ok, %Feature{}}

      iex> delete_feature(feature)
      {:error, %Ecto.Changeset{}}

  """
  def delete_feature(%Feature{} = feature) do
    Repo.delete(feature)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking feature changes.

  ## Examples

      iex> change_feature(feature)
      %Ecto.Changeset{data: %Feature{}}

  """
  def change_feature(%Feature{} = feature, attrs \\ %{}) do
    Feature.changeset(feature, attrs)
  end

  # Label context functions

  def list_labels(user) do
    Label
    |> where([l], l.user_id == ^user.id)
    |> Repo.all()
  end

  def change_label(%Label{} = label, attrs \\ %{}) do
    Label.changeset(label, attrs)
  end

  def create_label(attrs, user) do
    attrs = Map.put(attrs, "user_id", user.id)
    %Label{}
    |> Label.changeset(attrs)
    |> Repo.insert()
  end

  def duplicate_app(original_app, user) do
    original_app = Repo.preload(original_app, :features)

    Repo.transaction(fn ->
      new_app_attrs = %{
        name: "Copy of #{original_app.name}",
        icon: original_app.icon,
        description: original_app.description,
        status: "Idea",
        visibility: "private",
        category: original_app.category,
        custom_fields: original_app.custom_fields,
        pr_link: nil
      }

      {:ok, new_app} = create_app(new_app_attrs, user)

      for feature <- original_app.features do
        feature_attrs = %{
          title: feature.title,
          description: feature.description,
          how_to_add: feature.how_to_add,
          why: feature.why,
          pros: feature.pros,
          cons: feature.cons,
          implementation_date: feature.implementation_date,
          how_to_implement: feature.how_to_implement,
          why_need: feature.why_need,
          time_estimate: feature.time_estimate,
          app_id: new_app.id
        }

        create_feature(feature_attrs, user)
      end

      Repo.preload(new_app, [:user, :labels, :features, :children, :last_updated_by, :likes, app_members: [:user]])
    end)
  end

  # App members (team access for private apps)
  def list_app_members(%App{} = app) do
    AppMember
    |> where([m], m.app_id == ^app.id)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  def add_app_member(%App{} = app, %AppPlanner.Accounts.User{} = user, role \\ "viewer") do
    %AppMember{}
    |> AppMember.changeset(%{app_id: app.id, user_id: user.id, role: role})
    |> Repo.insert()
  end

  def remove_app_member(%App{} = app, user_id) do
    AppMember
    |> where([m], m.app_id == ^app.id and m.user_id == ^user_id)
    |> Repo.delete_all()
  end

  def can_edit_app?(%App{} = app, %AppPlanner.Accounts.User{} = user) do
    app.user_id == user.id or
      Enum.any?(app.app_members || [], fn m -> m.user_id == user.id and m.role == "editor" end)
  end

  def can_view_app?(%App{} = app, %AppPlanner.Accounts.User{} = user) do
    app.user_id == user.id or
      String.downcase(app.visibility || "") == "public" or
      Enum.any?(app.app_members || [], fn m -> m.user_id == user.id end)
  end

  # Like functionality
  alias AppPlanner.Planner.Like

  def like_app(app_id, user_id) do
    result =
      %Like{}
      |> Like.changeset(%{app_id: app_id, user_id: user_id})
      |> Repo.insert()

    broadcast_update(app_id)
    result
  end

  def unlike_app(app_id, user_id) do
    result =
      Like
      |> where([l], l.app_id == ^app_id and l.user_id == ^user_id)
      |> Repo.delete_all()

    broadcast_update(app_id)
    result
  end

  defp broadcast_update(app_id) do
    Phoenix.PubSub.broadcast(AppPlanner.PubSub, "app_updates", {:app_updated, app_id})
  end

  def liked_by?(app, user) do
    Enum.any?(app.likes || [], fn like -> like.user_id == user.id end)
  end
end
