defmodule PostionWeb.TopicReportController do
  use PostionWeb, :controller

  def word_count(conn, %{"id" => topic_id}) do
    report = topic_id |> Postion.Content.word_count!() |> render_word_count_report()
    filename = "topic-#{topic_id}-word-count.csv"
    send_download(conn, {:binary, report}, filename: filename, content_type: "text/csv")
  end

  defp render_word_count_report(report) do
    NimbleCSV.RFC4180.dump_to_iodata([["word", "count"] | Enum.map(report, &Tuple.to_list/1)])
  end
end
