# Postion

To start your Phoenix server:

  * Run `docker-compose up -d` to start docker dependencies
  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Adding Latency

  * You can [install Toxiproxy CLI](https://github.com/Shopify/toxiproxy#1-installing-toxiproxy) to add a Latency toxic to the running Toxiproxy inside docker

## Seeding Data
  
  * You can tweak the amount of data generated during `setup` (or `ecto.reset` if you want to reset the database) by passing the following env variables
    * `USER_COUNT` - How many users you should generate. In the demo I added around 50k.
    * `ROOT_TOPICS` - How many root topics you want to add
      * children topics will get smaller and smaller following a overly complicated function for no good reason
      * number of posts will be a random number, around 3.5 per topic
      * 20 will generate around a 300k topics with around 1kk posts, which is what I used in the demo
    * `POSTS_IN_HUGE_TOPIC` - For the particular huge topic, how many posts you want to generate. In the demo I used 500000.

## Generating Load

  * [Install k6](https://k6.io/docs/get-started/installation/)
  * Go to `load_test` directory
  * Run `./run.sh`

## Solutions to some problems

There is an extra commit with some of the solutions for the issues in these branches:

  * `fix-n-plus-1`
  * `optimize-topic-tree`

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
