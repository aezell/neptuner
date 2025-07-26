defmodule Neptuner.Accounts.UserNotifier do
  import Swoosh.Email

  alias Neptuner.Mailer
  alias Neptuner.Accounts.User

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Neptuner", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    deliver(user.email, "Log in instructions", """

    ==============================

    Hi #{user.email},

    You can log into your account by visiting the URL below:

    #{url}

    If you didn't request this email, please ignore this.

    ==============================
    """)
  end

  defp deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver organisation invitation instructions.
  """
  def deliver_organisation_invitation(invitation, organisation, inviter, url_fun) do
    url = url_fun.(invitation.token)

    deliver(invitation.email, "You're invited to join #{organisation.name}", """

    ==============================

    Hi #{invitation.email},

    #{inviter.email} has invited you to join "#{organisation.name}" as a #{invitation.role}.

    You can accept this invitation by visiting the URL below:

    #{url}

    This invitation will expire in 7 days.

    If you don't know #{inviter.email} or didn't expect this invitation, please ignore this email.

    ==============================
    """)
  end
end
