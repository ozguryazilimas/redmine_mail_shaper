require 'yaml'


namespace :redmine_mail_shaper do
  desc 'Convert data saved with YAML syck engine, to YAML psych engine'
  task :from_syck_to_psych => :environment do
    journal_detail_time_entries = JournalDetail.all.select{|k| k.property == 'time_entry'}
    puts "Migrating #{journal_detail_time_entries.count} entries"

    journal_detail_time_entries.each do |detail|
      puts "Workin on JournalDetail: #{detail.id}"
      use_syck
      parsed_syck = YAML.load(detail.old_value)
      activity_name = parsed_syck['activity_name'].force_encoding('UTF-8')
      activity_name_was = parsed_syck['activity_name_was'].force_encoding('UTF-8')

      use_psych
      parsed_syck['activity_name'] = activity_name
      parsed_syck['activity_name_was'] = activity_name_was
      parsed_psych = parsed_syck.to_yaml

      detail.old_value = parsed_psych
      detail.save!
    end
  end

  desc 'Check syck to psych data conversion'
  task :check_syck_to_psych => :environment do
    journal_detail_time_entries = JournalDetail.all.select{|k| k.property == 'time_entry'}
    puts "Checking #{journal_detail_time_entries.count} entries"

    binary_data = journal_detail_time_entries.select {|k| k.old_value =~ /!binary/}
    utf8_as_ascii = journal_detail_time_entries.select {|k| k.old_value =~ /\\x/}

    unless binary_data.blank?
      puts 'Binary data found'
      binary_data.each do |data|
        puts "JournalDetail ID: #{data.id}"
        pp data.old_value
      end
    end

    puts

    unless utf8_as_ascii.blank?
      puts 'Found some data that can be UTF-8 but presented as ASCII-8BIT'
      utf8_as_ascii.each do |data|
        puts "JournalDetail ID: #{data.id}"
        pp data.old_value
      end
    end
  end

  def use_syck
    YAML::ENGINE.yamler = 'syck'
    raise "Unable to switch to Syck" unless YAML == Syck
  end

  def use_psych
    YAML::ENGINE.yamler = 'psych'
    raise "Unable to switch to Psych" unless YAML == Psych
  end

end

