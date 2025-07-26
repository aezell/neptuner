defmodule Neptuner.Schema do
  @moduledoc """
  Base schema module for Neptuner.

  Provides common functionality for Ecto schemas with binary_id as the default primary key type,
  enabling UUID support across all schemas.

  ## Usage

      defmodule Neptuner.Accounts.User do
        use Neptuner.Schema
        
        schema "users" do
          field :email, :string
          field :name, :string
          
          timestamps()
        end
      end

  This will automatically set the primary key type to binary_id (UUID) and configure
  foreign key types to also use binary_id.
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end
end
