class SendWeeklyPayoutReportWorker < LunchproWorker

  def perform(*args)
    SparkpostMailer.send_weekly_payout_report.deliver!
  end
end
