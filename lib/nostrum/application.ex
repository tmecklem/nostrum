defmodule Nostrum.Application do
  @moduledoc false

  use Application

  require Logger

  @doc false
  def start(_, _) do
    import Supervisor.Spec

    case Application.get_env(:nostrum, :enabled, true) do
      false ->
        Logger.info("Skipping nostrum real supervisor start")
        Supervisor.start_link([], strategy: :one_for_one)
      _ ->
        if !Application.get_env(:nostrum, :token), do: raise("Please supply a token")

        num_shards = Application.get_env(:nostrum, :num_shards, 1)

        setup_ets_tables()

        children = [
          Nostrum.Api.Ratelimiter,
          Nostrum.Shard.Connector,
          Nostrum.Cache.CacheSupervisor,
          {Nostrum.Shard.Supervisor, num_shards}
        ]

        if Application.get_env(:nostrum, :dev, nil) do
          Supervisor.start_link(children ++ [supervisor(Dummy, [])], strategy: :one_for_one)
        else
          Supervisor.start_link(children, strategy: :one_for_one)
        end
    end
  end

  @doc false
  def setup_ets_tables do
    :ets.new(:gateway_url, [:set, :public, :named_table])
    :ets.new(:unavailable_guilds, [:set, :public, :named_table])
    :ets.new(:users, [:set, :public, :named_table])
    :ets.new(:channels, [:set, :public, :named_table])
    :ets.new(:presences, [:set, :public, :named_table])
    :ets.new(:guild_shard_map, [:set, :public, :named_table])
    :ets.new(:channel_guild_map, [:set, :public, :named_table])
  end
end
