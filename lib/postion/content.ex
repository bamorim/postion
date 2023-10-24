defmodule Postion.Content do
  @moduledoc """
  The Content context.
  """

  import Ecto.Query, warn: false

  alias Postion.Repo
  alias Postion.Content.Topic
  alias Postion.Content.Contributor
  alias Postion.Accounts.User

  @type topic_filter() :: {:parent_id, pos_integer() | nil}
  @type post_filter() :: {:topic_id, pos_integer()}
  @type pagination_opt() :: {:limit, pos_integer()} | {:offset, non_neg_integer()}

  @doc """
  Returns the list of topics.

  ## Examples

      iex> list_topics()
      [%Topic{}, ...]

      iex> list_topics(parent_id: 123)
      [%Topic{}, ...]

  """
  @spec list_topics([topic_filter()]) :: [%Topic{}]
  def list_topics(filters \\ []) do
    filters
    |> Enum.reduce(Topic, &filter_topic(&2, &1))
    |> Repo.all()
  end

  defp filter_topic(query, {:parent_id, nil}) do
    where(query, [topic], is_nil(topic.parent_id))
  end

  defp filter_topic(query, {:parent_id, parent_id}) do
    where(query, parent_id: ^parent_id)
  end

  @type topic_tree_result() :: %{required(pos_integer()) => {String.t(), topic_tree_result()}}

  @doc """
  Returns topics in a tree format where at each level we have a map from id to a tuple of format
  {name, children}, where children is the next level at the tree.
  """
  @spec topic_tree([%Topic{}]) :: topic_tree_result()
  def topic_tree(topics \\ list_topics()) do
    do_topic_tree(topics, nil, 1, 5)
  end

  defp do_topic_tree(_all_topics, _parent_id, level, level), do: %{}

  defp do_topic_tree(all_topics, parent_id, level, max_level) do
    all_topics
    |> Enum.filter(&(&1.parent_id == parent_id))
    |> Map.new(&{&1.id, {&1.name, do_topic_tree(all_topics, &1.id, level + 1, max_level)}})
  end

  @doc """
  Gets a single topic.

  Raises `Ecto.NoResultsError` if the Topic does not exist.

  ## Examples

      iex> get_topic!(123)
      %Topic{}

      iex> get_topic!(456)
      ** (Ecto.NoResultsError)

  """
  def get_topic!(id), do: Repo.get!(Topic, id)

  @doc """
  Creates a topic.

  ## Examples

      iex> create_topic(%{field: value})
      {:ok, %Topic{}}

      iex> create_topic(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_topic(attrs \\ %{}) do
    %Topic{}
    |> Topic.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a topic.

  ## Examples

      iex> update_topic(topic, %{field: new_value})
      {:ok, %Topic{}}

      iex> update_topic(topic, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_topic(%Topic{} = topic, attrs) do
    topic
    |> Topic.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a topic.

  ## Examples

      iex> delete_topic(topic)
      {:ok, %Topic{}}

      iex> delete_topic(topic)
      {:error, %Ecto.Changeset{}}

  """
  def delete_topic(%Topic{} = topic) do
    Repo.delete(topic)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking topic changes.

  ## Examples

      iex> change_topic(topic)
      %Ecto.Changeset{data: %Topic{}}

  """
  def change_topic(%Topic{} = topic, attrs \\ %{}) do
    Topic.changeset(topic, attrs)
  end

  alias Postion.Content.Post

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  @spec list_posts([post_filter() | pagination_opt()]) :: [%Post{}]
  def list_posts(opts \\ []) do
    {opts, filters} = Keyword.split(opts, [:limit, :offset, :preload])

    filters
    |> Enum.reduce(Post, &filter_post(&2, &1))
    |> limit(^Keyword.get(opts, :limit, 100))
    |> offset(^Keyword.get(opts, :offset, 0))
    |> order_by([p], desc: p.updated_at, desc: p.id)
    |> Repo.all()
    |> Repo.preload(Keyword.get(opts, :preload, []))
  end

  defp filter_post(query, {:topic_id, topic_id}) do
    where(query, topic_id: ^topic_id)
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post!(id), do: Post |> Repo.get!(id) |> Repo.preload(:contributors)

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%User{}, %{field: value})
      {:ok, %Post{}}

      iex> create_post(%User{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(%User{id: author_id}, attrs) do
    %Post{contributors: [%Contributor{author: true, user_id: author_id}]}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(user, post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(user, post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%User{id: user_id}, %Post{} = post, attrs) do
    changeset = Post.changeset(post, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:post, changeset)
    |> Ecto.Multi.insert(:contributor, %Contributor{user_id: user_id, post_id: post.id},
      on_conflict: :nothing
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{post: post}} -> {:ok, Repo.preload(post, :contributors, force: true)}
      {:error, :post, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  @doc """
  Returns a word count report for a given topic
  """
  @spec word_count!(non_neg_integer()) :: [{String.t(), non_neg_integer()}]
  def word_count!(topic_id) do
    topic = get_topic!(topic_id)

    Post
    |> filter_post({:topic_id, topic.id})
    |> Repo.all()
    |> Enum.flat_map(&Post.words/1)
    |> Enum.reduce(%{}, fn word, counts ->
      Map.update(counts, word, 1, &(&1 + 1))
    end)
    |> Enum.sort_by(&elem(&1, 1), :desc)
  end
end
