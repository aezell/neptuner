defmodule NeptunerWeb.WaitlistController do
  use NeptunerWeb, :controller

  alias Neptuner.Waitlist.Entry
  alias Neptuner.Repo

  def join(conn, %{"email" => _email} = params) do
    changeset = Entry.changeset(%Entry{}, params)

    case Repo.insert(changeset) do
      {:ok, _entry} ->
        conn
        |> put_flash(:info, "Thanks for joining our waitlist! We'll be in touch soon.")
        |> redirect(to: "/")

      {:error, %Ecto.Changeset{} = changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {k, v}, acc ->
              String.replace(acc, "%{#{k}}", to_string(v))
            end)
          end)

        error_message =
          case errors do
            %{email: [msg | _]} -> "Email " <> msg
            _ -> "There was an error joining the waitlist. Please try again."
          end

        conn
        |> put_flash(:error, error_message)
        |> redirect(to: "/")
    end
  end
end
