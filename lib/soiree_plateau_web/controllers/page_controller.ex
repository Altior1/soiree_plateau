defmodule SoireePlateauWeb.PageController do
  use SoireePlateauWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
