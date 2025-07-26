# Waitlist feature flag setup

# Enable waitlist mode by default
case FunWithFlags.enable(:waitlist_mode) do
  {:ok, _flag} -> IO.puts("✓ Waitlist mode enabled")
  {:error, err} -> IO.puts("✗ Failed to enable waitlist mode: #{inspect(err)}")
end
