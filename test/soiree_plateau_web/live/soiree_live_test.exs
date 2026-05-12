defmodule SoireePlateauWeb.SoireeLiveTest do
  use SoireePlateauWeb.ConnCase

  import Phoenix.LiveViewTest
  import SoireePlateau.TeufFixtures

  @create_attrs %{
    date: "2026-05-11T13:00:00",
    home: "some home",
    title: "some title",
    capacity: 42
  }
  @update_attrs %{
    date: "2026-05-12T13:00:00",
    home: "some updated home",
    title: "some updated title",
    capacity: 43
  }
  @invalid_attrs %{date: nil, home: nil, title: nil, capacity: nil}

  setup :register_and_log_in_user

  defp create_soiree(%{scope: scope}) do
    soiree = soiree_fixture(scope)

    %{soiree: soiree}
  end

  describe "Index" do
    setup [:create_soiree]

    test "lists all soirees", %{conn: conn, soiree: soiree} do
      {:ok, _index_live, html} = live(conn, ~p"/soirees")

      assert html =~ "Listing Soirees"
      assert html =~ soiree.title
    end

    test "saves new soiree", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/soirees")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Soiree")
               |> render_click()
               |> follow_redirect(conn, ~p"/soirees/new")

      assert render(form_live) =~ "New Soiree"

      assert form_live
             |> form("#soiree-form", soiree: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#soiree-form", soiree: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/soirees")

      html = render(index_live)
      assert html =~ "Soiree created successfully"
      assert html =~ "some title"
    end

    test "updates soiree in listing", %{conn: conn, soiree: soiree} do
      {:ok, index_live, _html} = live(conn, ~p"/soirees")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#soirees-#{soiree.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/soirees/#{soiree}/edit")

      assert render(form_live) =~ "Edit Soiree"

      assert form_live
             |> form("#soiree-form", soiree: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#soiree-form", soiree: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/soirees")

      html = render(index_live)
      assert html =~ "Soiree updated successfully"
      assert html =~ "some updated title"
    end

    test "deletes soiree in listing", %{conn: conn, soiree: soiree} do
      {:ok, index_live, _html} = live(conn, ~p"/soirees")

      assert index_live |> element("#soirees-#{soiree.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#soirees-#{soiree.id}")
    end
  end

  describe "Show" do
    setup [:create_soiree]

    test "displays soiree", %{conn: conn, soiree: soiree} do
      {:ok, _show_live, html} = live(conn, ~p"/soirees/#{soiree}")

      assert html =~ "Show Soiree"
      assert html =~ soiree.title
    end

    test "updates soiree and returns to show", %{conn: conn, soiree: soiree} do
      {:ok, show_live, _html} = live(conn, ~p"/soirees/#{soiree}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/soirees/#{soiree}/edit?return_to=show")

      assert render(form_live) =~ "Edit Soiree"

      assert form_live
             |> form("#soiree-form", soiree: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#soiree-form", soiree: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/soirees/#{soiree}")

      html = render(show_live)
      assert html =~ "Soiree updated successfully"
      assert html =~ "some updated title"
    end
  end
end
