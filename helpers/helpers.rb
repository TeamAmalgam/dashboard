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

end
