defmodule Commanded.ProcessManagers.Supervisor do
  @moduledoc false

  use Supervisor

  require Logger

  def start_link(command_dispatcher, process_router) do
    Supervisor.start_link(__MODULE__, [command_dispatcher, process_router])
  end

  def start_process_manager(
        supervisor,
        process_manager_name,
        process_manager_module,
        process_uuid
      ) do
    Logger.debug(fn ->
      "Starting process manager process for `#{process_manager_module}` with uuid #{process_uuid}"
    end)

    Supervisor.start_child(supervisor, [
      process_manager_name,
      process_manager_module,
      process_uuid
    ])
  end

  def init([command_dispatcher, process_router]) do
    children = [
      worker(
        Commanded.ProcessManagers.ProcessManagerInstance,
        [command_dispatcher, process_router],
        restart: :temporary
      )
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
