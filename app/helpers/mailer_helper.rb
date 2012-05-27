module MailerHelper
  include ApplicationHelper

  def truncate_for_mail_shaper(str_full)
    max_lines = [Setting[:plugin_redmine_mail_shaper][:diff_max_lines_displayed].to_i, 0].max

    unless max_lines == 0
      str_truncated = str_full.split(/\n/, max_lines+1)[0...max_lines].join("\n")
      truncated = (str_full.count("\n") > max_lines)

      str_truncated << "\n" << l(:text_diff_truncated) if truncated
    else
      str_truncated = str_full
    end

    str_truncated
  end

end

