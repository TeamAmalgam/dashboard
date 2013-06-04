helpers do

  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    username, password = settings.auth_username, settings.auth_password

    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [username, password]
  end

  def pretty_timestamp(timestamp)
    return nil if timestamp.nil?

    return timestamp.strftime("%R") if timestamp.today?
    return timestamp.strftime("%B %e at %R") if timestamp.year == Time.now.year
    timestamp.strftime("%B %e %G at %R")
  end

  def pretty_duration(total_seconds)
    return nil if total_seconds.nil?

    seconds = total_seconds % 60
    minutes = (total_seconds / 60) % 60
    hours = total_seconds / (60 * 60)

    format("%02d:%02d:%02d", hours, minutes, seconds)
  end

  def test_result_icon(test_result)
    return nil if test_result.nil?

    string = '<i data-toggle="tooltip" data-placement="left" class="'
    string +=
      if test_result.pending? then
        'icon-question-sign" title="Pending"></i>'
      elsif test_result.correct? then
        'icon-ok" title="Correct"></i>'
      else
        'icon-remove" title="Failed"></i>'
    end
  end

  def test_result_row_class(test_result)
    return nil if test_result.nil?

    return "warning" if test_result.pending?
    return "success" if test_result.correct?
    "error"
  end

  def test_result_status_number(test_result)
    return nil if test_result.nil?

    return 0 if test_result.pending?
    return 2 if test_result.correct?
    1
  end

  def test_type(test_result)
    return nil if test_result.nil?

    case test_result.test_type
    when TestResult::TestTypes::PERFORMANCE
      "Performance"
    when TestResult::TestTypes::CORRECTNESS
      "Correctness"
    when TestResult::TestTypes::CONTINUOUS_INTEGRATION
      "CI"
    else
      "Unknown"
    end
  end

  def test_result_s3_link test_result
    return if test_result.nil?

    s3_link = test_result.tarball_s3_link
    s3_link.nil? ? "&nbsp;" : "<a href='#{s3_link}'>link</a>"
  end

  def model_s3_link model
    return if model.nil?

    s3_link = model.s3_link
    s3_link.nil? ? "&nbsp;" : "<a href='#{s3_link}'>link</a>"
  end

  # Sums the duration of all the most recent completed models
  # Note the use of terminology. "Tests" might refer to unit tests.
  # In this case, "tests" refers to running a model.
  def total_model_time
    Model.includes(:last_completed_test).all
      .map(&:last_completed_test)
      .reject{|t| t.nil?}
      .map{|t| t.runtime_seconds}
      .sum
  end

  def number_pending_models
    Model.includes(:last_test).all
      .map(&:last_test)
      .select{|t| !t.nil? && t.pending?}
      .count
  end

  def number_failing_models
    Model.includes(:last_completed_test).all
      .map(&:last_completed_test)
      .select{|t| !t.nil? && !t.correct?}
      .count
  end

  def test_run_data_array(test_results)
    index = -1 
    "[\n" + test_results.collect do |result|
      index += 1
      entry = <<-ENTRY
      { 
        index: #{index}, 
        completed: #{result.completed? ? 1 : 0},
        correct: #{result.correct? ? 1 : 0},
        datetime: new Date("#{result.requested_at.to_datetime.to_s}"),
        runtime_seconds: #{result.runtime_seconds},
        pretty_duration: "#{pretty_duration result.runtime_seconds}"
      }
      ENTRY
    end.join(",\n") + "\n]\n"
  end

  def worker_status_row_class(worker)
    return nil if worker.nil?

    return "success" if worker.last_heartbeat > 5.minutes.ago
    return "warning" if worker.last_heartbeat > 10.minutes.ago
    "error"
  end

  def worker_status_icon(worker)
    return nil if worker.nil?

    string = '<i data-toggle="tooltip" data-placement="left" class="'
    string +=
      if worker.last_heartbeat > 5.minutes.ago then       # within 5 min
        'icon-ok" title="OK"></i>'
      elsif worker.last_heartbeat > 10.minutes.ago then   # within 10 min
        'icon-question-sign" title="Warning"></i>'
      else
        'icon-remove" title="Failed"></i>'
    end
  end

  def worker_state_message(worker)
    return nil if worker.nil?

    return "Waiting for job." if worker.test_result.nil?
    return "Running #{worker.test_result.model.friendly_name}"
  end
end
