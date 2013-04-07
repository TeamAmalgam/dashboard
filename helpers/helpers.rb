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

  def test_type(test_result)
    return nil if test_result.nil?

    case test_result.test_type
    when TestResult::TestTypes::PERFORMANCE
      "Performance"
    when TestResult::TestTypes::CORRECTNESS
      "Correctness"
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

  # Sums the duration of all the most recent completed tests
  def total_test_time
    Model.all
      .map(&:last_completed_test)
      .reject{|t| t.nil?}
      .map{|t| t.runtime_seconds}
      .sum
  end

  def number_pending_tests
    Model.all
      .map(&:last_test)
      .select{|t| !t.nil? && t.pending?}
      .count
  end

  def number_failing_tests
    Model.all
      .map(&:last_completed_test)
      .select{|t| !t.nil? && !t.correct?}
      .count
  end

end
