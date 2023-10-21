import Ecto.Query

alias Postion.Repo
alias Postion.Accounts.User
alias Postion.Content.Topic
alias Postion.Content.Post
alias Postion.Content.Contributor

require Logger

Logger.configure(level: :error)

defmodule Inserter do
  def insert_all(params, schema, inserted_at, inc \\ fn _ -> :ok end) do
    params
    |> Stream.map(fn param ->
      if is_nil(inserted_at) do
        param
      else
        Map.merge(param, %{
          inserted_at: {:placeholder, :inserted_at},
          updated_at: {:placeholder, :inserted_at}
        })
      end
    end)
    |> Stream.chunk_every(10_000)
    |> Task.async_stream(fn params ->
      Repo.transaction(
        fn ->
          Repo.insert_all(schema, params, placeholders: %{inserted_at: inserted_at})
        end,
        timeout: :infinity
      )

      inc.(length(params))
    end)
    |> Stream.run()
  end
end

defmodule UserSeed do
  def seed_users(size \\ 1000) do
    pw = Bcrypt.hash_pwd_salt("123412341234")
    confirmed_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    inserted_at = DateTime.utc_now() |> DateTime.truncate(:second)

    1..size
    |> Enum.map(fn _ ->
      %{
        email: Faker.Internet.email(),
        hashed_password: pw,
        confirmed_at: confirmed_at,
        inserted_at: inserted_at,
        updated_at: inserted_at
      }
    end)
    |> then(&Repo.insert_all(User, &1))
  end
end

defmodule TopicSeed do
  def seed_topics(size \\ 20) do
    Owl.ProgressBar.start(id: :topics, label: "Creating topics", total: estimate_total(size))

    seed_topics([{nil, ""}], size, &Owl.ProgressBar.inc(id: :topics, step: &1))
  end

  def seed_topics([], _, _) do
    :ok
  end

  def seed_topics(parent_data, size, inc) do
    inserted_at = DateTime.utc_now() |> DateTime.truncate(:second)

    params =
      for i <- range_for(size), {parent_id, prefix} <- parent_data do
        %{
          name: "#{prefix}#{i} #{Faker.Pokemon.name()}",
          parent_id: parent_id
        }
      end

    Inserter.insert_all(params, Topic, inserted_at, inc)

    query =
      case parent_data do
        [{nil, _}] -> topic_query(nil, inserted_at)
        parents -> parents |> Enum.map(&elem(&1, 0)) |> topic_query(inserted_at)
      end

    query
    |> Repo.all()
    |> Enum.map(fn %{id: id, name: name} ->
      prefix = name |> String.split(" ") |> Enum.at(0)
      prefix = prefix <> "."
      {id, prefix}
    end)
    |> seed_topics(reduce_size(size), inc)
  end

  defp range_for(0), do: []
  defp range_for(size), do: 1..size

  defp estimate_total(size, totals \\ [])
  defp estimate_total(0, totals), do: Enum.sum(totals)
  defp estimate_total(size, []), do: estimate_total(reduce_size(size), [size])

  defp estimate_total(size, [prev | _] = totals) do
    estimate_total(reduce_size(size), [prev * size | totals])
  end

  defp reduce_size(size) when size <= 1, do: 0
  defp reduce_size(size), do: max(min(trunc(size - :math.log2(size)), size - 2), 0)

  defp topic_query(parent_id, inserted_at)

  defp topic_query(nil, inserted_at) do
    where(Topic, [t], is_nil(t.parent_id) and t.inserted_at == ^inserted_at)
  end

  defp topic_query(parent_ids, inserted_at) do
    where(Topic, [t], t.parent_id in ^parent_ids and t.inserted_at == ^inserted_at)
  end
end

defmodule PostGenerator do
  def generate(topic_id) do
    %{
      topic_id: topic_id,
      content: gen_post_content(),
      title: gen_post_title()
    }
  end

  defp gen_post_content do
    paragraphs = Enum.random(2..8)

    content =
      1..paragraphs
      |> Enum.map(fn _ -> gen_paragraph() end)
      |> Enum.join("\n\n")

    with_title(content)
  end

  defp gen_paragraph do
    generator =
      Enum.random([
        &gen_sentences_paragraph/0,
        &gen_sentences_paragraph/0,
        &gen_markdown/0
      ])

    with_title(generator.(), "##")
  end

  defp with_title(content, md \\ "#") do
    Enum.join(["#{md} #{gen_post_title()}", content], "\n\n")
  end

  defp gen_markdown do
    generator =
      Enum.random([
        &Faker.Markdown.ordered_list/0,
        &Faker.Markdown.unordered_list/0
      ])

    generator.()
  end

  defp gen_post_title do
    String.capitalize(Faker.Company.catch_phrase())
  end

  defp gen_sentences_paragraph do
    sentences = Enum.random(2..8)

    generator =
      Enum.random([
        &Faker.Lorem.Shakespeare.as_you_like_it/0,
        &Faker.Lorem.Shakespeare.hamlet/0,
        &Faker.Lorem.Shakespeare.king_richard_iii/0,
        &Faker.Lorem.Shakespeare.romeo_and_juliet/0
      ])

    1..sentences
    |> Enum.map(fn _ -> generator.() end)
    |> Enum.join(" ")
  end
end

defmodule ContributorSeed do
end

defmodule PostSeed do
  def seed_posts do
    inserted_at = DateTime.utc_now() |> DateTime.truncate(:second)
    topic_count = Repo.aggregate(Topic, :count)
    # This is an estimate
    total = trunc(topic_count * 3.5) + 1
    Owl.ProgressBar.start(id: :posts, label: "Creating posts", total: total)

    Repo.transaction(
      fn ->
        Topic
        |> select([t], t.id)
        |> Repo.stream(max_rows: 50_000)
        |> Stream.flat_map(fn topic_id ->
          post_count = Enum.random(2..5)

          for _ <- 1..post_count do
            PostGenerator.generate(topic_id)
          end
        end)
        |> Inserter.insert_all(Post, inserted_at, &Owl.ProgressBar.inc(id: :posts, step: &1))
      end,
      timeout: :infinity
    )

    seed_contributors(inserted_at)
  end

  defp seed_contributors(inserted_at) do
    posts = where(Post, inserted_at: ^inserted_at)
    post_count = Repo.aggregate(posts, :count)
    # This is an estimation
    total = trunc(post_count * 3.5)

    Owl.ProgressBar.start(id: :contributors, label: "Creating contributors", total: total)

    users = Repo.all(User)
    all_ids = posts |> select([p], p.id) |> Repo.all()

    all_ids
    |> Stream.flat_map(fn post_id ->
      contributors = Enum.random(1..6)

      users =
        users
        |> Enum.shuffle()
        |> Enum.take(contributors)

      for user <- users do
        %{
          post_id: post_id,
          user_id: user.id
        }
      end
      |> List.update_at(0, &Map.put(&1, :author, true))
    end)
    |> Inserter.insert_all(
      Contributor,
      nil,
      &Owl.ProgressBar.inc(id: :contributors, step: &1)
    )
  end
end

defmodule ProblemSeed do
  # This seeds specific problems, like a topic with too many posts and a post with too many contributors.
  def seed_problems do
    topic = Repo.insert!(%Topic{name: "99 Problems"})
    Repo.insert!(%Topic{name: "But a b ain't one", parent_id: topic.id})

    with_spinner(
      "Inserting huge topic",
      fn -> {:ok, insert_huge_topic(topic.id)} end
    )

    with_spinner(
      "Inserting post with many contributors",
      fn -> {:ok, insert_post_with_many_contributors(topic.id)} end
    )
  end

  defp with_spinner(phase, fun) do
    Owl.Spinner.run(
      fun,
      labels: [
        ok: "Done: #{phase}",
        error: "Failed: #{phase}",
        processing: "#{phase}..."
      ]
    )
  end

  defp insert_huge_topic(parent_id) do
    topic = Repo.insert!(%Topic{name: "Huge Topic", parent_id: parent_id})

    base =
      from(gen in fragment("select generate_series(?::integer, ?::integer) as num", ^1, ^100_000))

    query =
      select(base, [gen], %{
        title: fragment("CONCAT('Post ', ?::text)", gen.num),
        content: "Hello **world**",
        inserted_at: type(^topic.inserted_at, :utc_datetime),
        updated_at: type(^topic.inserted_at, :utc_datetime),
        topic_id: type(^topic.id, :id)
      })

    Repo.transaction(
      fn ->
        Repo.insert_all(Post, query)
      end,
      timeout: :infinity
    )

    user = User |> Repo.all() |> Enum.random()

    contributor_query =
      Post
      |> where(inserted_at: ^topic.inserted_at)
      |> select([p], %{post_id: p.id, author: true, user_id: ^user.id})

    Repo.transaction(
      fn ->
        Repo.insert_all(Contributor, contributor_query)
      end,
      timeout: :infinity
    )
  end

  defp insert_post_with_many_contributors(topic_id) do
    post =
      topic_id
      |> PostGenerator.generate()
      |> then(&struct!(Post, &1))
      |> Map.put(:title, "Too Many Contributors")
      |> Repo.insert!()

    query = select(User, [u], %{user_id: u.id, post_id: ^post.id, author: false})

    Repo.transaction(
      fn ->
        Repo.insert_all(Contributor, query)
      end,
      timeout: :infinity
    )

    Contributor
    |> where(post_id: ^post.id)
    |> limit(1)
    |> Repo.one!()
    |> Ecto.Changeset.cast(%{author: true}, [:author])
    |> Repo.update!()
  end
end

UserSeed.seed_users()
TopicSeed.seed_topics()
PostSeed.seed_posts()
ProblemSeed.seed_problems()
Owl.LiveScreen.await_render()
