defmodule AppPlanner.NotesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `AppPlanner.Notes` context.
  """

  @doc """
  Generate a note.
  """
  def note_fixture(attrs \\ %{}) do
    {:ok, note} =
      attrs
      |> Enum.into(%{
        description: "some description",
        heading: "some heading",
        status: "some status"
      })
      |> AppPlanner.Notes.create_note()

    note
  end
end
