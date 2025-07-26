defmodule NeptunerWeb.ChangelogController do
  use NeptunerWeb, :controller

  def index(conn, _params) do
    changelog_entries = [
      %{
        version: "1.2.0",
        date: "2025-01-15",
        type: "feature",
        title: "New Dashboard Analytics",
        description:
          "Added comprehensive analytics dashboard with real-time metrics and custom date ranges."
      },
      %{
        version: "1.1.5",
        date: "2025-01-10",
        type: "improvement",
        title: "Enhanced User Experience",
        description:
          "Improved page load times by 40% and enhanced mobile responsiveness across all pages."
      },
      %{
        version: "1.1.4",
        date: "2025-01-08",
        type: "bugfix",
        title: "Authentication Fixes",
        description: "Fixed login issues and improved session management for better security."
      },
      %{
        version: "1.1.3",
        date: "2025-01-05",
        type: "feature",
        title: "Team Collaboration",
        description:
          "Added team invitation system and role-based permissions for workspace management."
      },
      %{
        version: "1.1.2",
        date: "2025-01-02",
        type: "improvement",
        title: "API Rate Limiting",
        description:
          "Implemented intelligent rate limiting to ensure fair usage and system stability."
      },
      %{
        version: "1.1.1",
        date: "2024-12-28",
        type: "bugfix",
        title: "Data Export Issues",
        description:
          "Resolved CSV export formatting problems and added support for larger datasets."
      },
      %{
        version: "1.1.0",
        date: "2024-12-20",
        type: "feature",
        title: "Advanced Search",
        description:
          "Introduced powerful search functionality with filters, sorting, and saved search queries."
      },
      %{
        version: "1.0.8",
        date: "2024-12-15",
        type: "improvement",
        title: "Performance Optimization",
        description:
          "Optimized database queries and reduced memory usage for better overall performance."
      }
    ]

    render(conn, :index, changelog_entries: changelog_entries)
  end
end
