class Ssu < Thor
  desc 'sync ID', 'add a bank sync job to the queue for creds with id ID'
  def sync(id)
    environment

    account_cred = AccountCred.find_by_id(id)

    if account_cred.nil?
      abort "Unable to find cred:#{id}."
    end

    enqueue(account_cred)
  end

  desc 'sync-all', 'add a bank sync job for each credential to the queue'
  def sync_all
    environment

    AccountCred.all.each {|c| enqueue(c) }
  end

  desc 'cleanup-profiles', 'removes profiles older than a week and archives profiles older than a day'
  def cleanup_profiles
    environment
    extend ActionView::Helpers::DateHelper

    SSU::Profile.all.each do |profile|
      if profile.created_at < 1.week.ago
        puts "Removing profile: #{profile}"
        profile.destroy
      elsif profile.created_at < 1.day.ago
        puts "Archiving profile: #{profile}"
        profile.archive
      else
        puts "Ignoring profile: #{profile} (created #{time_ago_in_words(profile.created_at)} ago)"
      end
    end
  end

  no_tasks do
    def enqueue(cred)
      cred.enqueue_sync
      puts "Added sync job for cred:#{cred.id} to the queue."
    end

    def environment
      require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')
    end
  end
end
