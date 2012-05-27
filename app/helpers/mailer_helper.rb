module MailerHelper
  include ApplicationHelper

  def truncate_for_mail_shaper(str_full)
    max_lines = [Setting[:plugin_redmine_mail_shaper][:diff_max_lines_displayed].to_i, 0].max
    newline_seperator = "\r\n"

    unless max_lines == 0
      str_truncated = str_full.split(newline_seperator, max_lines+1)[0...max_lines].join(newline_seperator)
      truncated = (str_full.count(newline_seperator) > max_lines)
      span_diff_size = str_truncated.scan('<span class="diff_').size - str_truncated.scan('</span>').size

      str_truncated << newline_seperator << '</span>' * span_diff_size
      str_truncated << newline_seperator << l(:text_diff_truncated) if truncated
    else
      str_truncated = str_full
    end

    str_truncated
  end

end

