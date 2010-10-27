require 'pathname'

class Snapshot < ActiveRecord::Base
  belongs_to :user

  before_validation :generate_uid, :on => :create
  after_destroy :remove_files

  validates_uniqueness_of :user_id, :uid
  validates_presence_of :uid

  def build
    Exporter::Wesabe.new.write(user, archive)
    update_attribute :built_at, Time.now
    update_attribute :error, nil
  rescue => e
    update_attribute :error, [e, *e.backtrace].join("\n")
    raise e
  end

  def import
    self.user = Importer::Wesabe.new.import(archive)
  end

  def archive
    Pathname.new(File.join(ApiEnv::FILE_PATH, 'snapshots', "#{uid}.zip"))
  end

  def built?
    archive.exist?
  end

  def self.async_build_snapshot_for_user(user)
    user.snapshot.destroy if user.snapshot
    Resque.enqueue(BuildSnapshot, create!(:user => user).id)
  end

  private

  def generate_uid
    self.uid = UID.generate
  end

  def remove_files
    archive.unlink if archive.exist?
  end

  class BuildSnapshot
    @queue = :normal

    def self.perform(snapshot_id)
      snapshot = Snapshot.find(snapshot_id)
      snapshot.build
    end
  end
end