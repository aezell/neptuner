defmodule NeptunerWeb.TourComponents do
  @moduledoc """
  Tour and tutorial components for progressive feature introduction.
  """
  use Phoenix.Component
  import NeptunerWeb.CoreComponents

  @doc """
  Renders a feature highlight tooltip that points to specific elements.
  """
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :content, :string, required: true
  attr :position, :string, default: "bottom", values: ~w(top bottom left right)
  attr :target_selector, :string, required: true
  attr :step, :integer, required: true
  attr :total_steps, :integer, required: true
  attr :show, :boolean, default: false

  def feature_highlight(assigns) do
    ~H"""
    <div
      id={@id}
      class={"fixed z-50 transition-all duration-300 #{if @show, do: "opacity-100", else: "opacity-0 pointer-events-none"}"}
      phx-hook="FeatureHighlight"
      data-target={@target_selector}
      data-position={@position}
    >
      <div class="bg-white rounded-lg shadow-lg border border-gray-200 p-4 max-w-sm">
        <div class="flex items-center justify-between mb-3">
          <h4 class="font-semibold text-gray-900">{@title}</h4>
          <div class="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">
            {@step}/{@total_steps}
          </div>
        </div>

        <p class="text-sm text-gray-600 mb-4">{@content}</p>

        <div class="flex justify-between items-center">
          <button phx-click="tour_skip" class="text-xs text-gray-500 hover:text-gray-700">
            Skip Tour
          </button>

          <div class="flex space-x-2">
            <%= if @step > 1 do %>
              <button
                phx-click="tour_previous"
                class="text-xs bg-gray-100 hover:bg-gray-200 text-gray-700 px-3 py-1 rounded"
              >
                Previous
              </button>
            <% end %>

            <button
              phx-click="tour_next"
              phx-value-step={@step}
              class="text-xs bg-purple-600 hover:bg-purple-700 text-white px-3 py-1 rounded"
            >
              {if @step < @total_steps, do: "Next", else: "Finish"}
            </button>
          </div>
        </div>
      </div>
      
    <!-- Tooltip arrow -->
      <div class={"absolute w-3 h-3 bg-white border transform rotate-45 #{arrow_position(@position)}"}>
      </div>
    </div>

    <!-- Backdrop overlay -->
    <div
      class={"fixed inset-0 z-40 transition-all duration-300 #{if @show, do: "bg-black bg-opacity-20", else: "pointer-events-none"}"}
      phx-click="tour_skip"
    >
    </div>
    """
  end

  @doc """
  Renders a welcome banner for new features.
  """
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :icon, :string, default: "hero-sparkles"
  attr :show, :boolean, default: false
  attr :dismissible, :boolean, default: true

  def feature_banner(assigns) do
    ~H"""
    <div
      id={@id}
      class={"relative bg-gradient-to-r from-purple-600 to-blue-600 text-white rounded-lg p-4 mb-6 transition-all duration-300 #{if @show, do: "opacity-100 translate-y-0", else: "opacity-0 -translate-y-2 pointer-events-none"}"}
      role="banner"
    >
      <div class="flex items-start space-x-3">
        <div class="flex-shrink-0">
          <.icon name={@icon} class="w-6 h-6" />
        </div>

        <div class="flex-1">
          <h3 class="font-semibold text-lg">{@title}</h3>
          <p class="text-purple-100 mt-1">{@description}</p>
        </div>

        <%= if @dismissible do %>
          <button
            phx-click="dismiss_banner"
            phx-value-banner={@id}
            class="flex-shrink-0 text-purple-200 hover:text-white"
          >
            <.icon name="hero-x-mark" class="w-5 h-5" />
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders a progress indicator for multi-step processes.
  """
  attr :steps, :list, required: true
  attr :current_step, :integer, required: true
  attr :class, :string, default: ""

  def step_progress(assigns) do
    ~H"""
    <div class={"flex items-center space-x-4 #{@class}"}>
      <div :for={{step, index} <- Enum.with_index(@steps, 1)} class="flex items-center">
        
    <!-- Step circle -->
        <div class={"flex items-center justify-center w-8 h-8 rounded-full text-sm font-medium #{step_circle_class(index, @current_step)}"}>
          <%= if index < @current_step do %>
            <.icon name="hero-check" class="w-4 h-4" />
          <% else %>
            {index}
          <% end %>
        </div>
        
    <!-- Step label -->
        <span class={"ml-2 text-sm #{step_label_class(index, @current_step)}"}>
          {step.title}
        </span>
        
    <!-- Connector line -->
        <%= if index < length(@steps) do %>
          <div class={"ml-4 w-12 h-0.5 #{step_connector_class(index, @current_step)}"}></div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders an interactive hotspot that pulses to draw attention.
  """
  attr :id, :string, required: true
  attr :target_selector, :string, required: true
  attr :show, :boolean, default: false
  attr :size, :string, default: "md", values: ~w(sm md lg)

  def hotspot(assigns) do
    ~H"""
    <div
      id={@id}
      class={"fixed z-30 pointer-events-none transition-all duration-300 #{if @show, do: "opacity-100", else: "opacity-0"}"}
      phx-hook="Hotspot"
      data-target={@target_selector}
    >
      <div class={"animate-pulse #{hotspot_size_class(@size)}"}>
        <!-- Outer ring -->
        <div class="absolute inset-0 bg-purple-400 rounded-full animate-ping opacity-20"></div>
        <!-- Middle ring -->
        <div class="absolute inset-1 bg-purple-500 rounded-full animate-ping opacity-40"></div>
        <!-- Inner dot -->
        <div class="absolute inset-2 bg-purple-600 rounded-full"></div>
      </div>
    </div>
    """
  end

  # Helper functions for styling

  defp arrow_position("top"),
    do: "-bottom-1.5 left-1/2 transform -translate-x-1/2 border-t border-l"

  defp arrow_position("bottom"),
    do: "-top-1.5 left-1/2 transform -translate-x-1/2 border-b border-r"

  defp arrow_position("left"),
    do: "-right-1.5 top-1/2 transform -translate-y-1/2 border-l border-b"

  defp arrow_position("right"),
    do: "-left-1.5 top-1/2 transform -translate-y-1/2 border-r border-t"

  defp step_circle_class(index, current_step) do
    cond do
      index < current_step -> "bg-green-500 text-white"
      index == current_step -> "bg-purple-600 text-white"
      true -> "bg-gray-200 text-gray-600"
    end
  end

  defp step_label_class(index, current_step) do
    cond do
      index < current_step -> "text-green-600 font-medium"
      index == current_step -> "text-purple-600 font-medium"
      true -> "text-gray-500"
    end
  end

  defp step_connector_class(index, current_step) do
    if index < current_step, do: "bg-green-500", else: "bg-gray-300"
  end

  defp hotspot_size_class("sm"), do: "w-4 h-4"
  defp hotspot_size_class("md"), do: "w-6 h-6"
  defp hotspot_size_class("lg"), do: "w-8 h-8"
end
