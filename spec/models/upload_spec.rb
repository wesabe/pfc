require 'spec_helper'


describe Upload do
  before do
    @account = Account.make
    @user = @account.user
    @upload = Upload.make(:account_key => @account.account_key, :user_id => @user.id)
    FileUtils.mkdir_p(@upload.filepath.dirname)
    File.new(@upload.filepath, 'w')
  end

  describe "creating a new upload" do
    it "generates a guid" do
      @upload.save
      @upload.guid.should match(/^\w{8}$/)
    end
  end

  describe "being deleted" do
    it "deletes its associated statement file" do
      lambda { @upload.destroy }.
        should change { @upload.filepath.exist? }.from(true).to(false)
    end

    it "does not explode if the statement file has already been deleted" do
      @upload.filepath = "/tmp/non_existent_file"
      lambda { @upload.destroy }.should_not raise_error
    end
  end

  describe "uploading data" do
    it_should_behave_like "it has a logged-in user"

    before do
      @akey     = current_user.account_key
      @checking = Account.make(:account_key => @akey)
      @savings  = Account.make(:account_key => @akey)
      @txaction = Txaction.make(:account => @checking, :upload => @upload)
      AccountUpload.create(:upload => @upload, :account => @checking)
    end

    shared_examples_for "an Upload with any number of accounts" do
      it "unlinks transfers of deleted Txactions" do
        @txfer = Txaction.make(:account => @savings)
        @txaction.set_transfer_buddy!(@txfer)

        lambda { @upload.destroy_for_account(@checking) }.
          should change { @txfer.reload.transfer_buddy }.
                  from(@txaction).
                  to(nil)
      end

      it "makes transfers of deleted Txactions no longer paired" do
        @txfer = Txaction.make(:account => @savings)
        @txaction.set_transfer_buddy!(@txfer)

        lambda { @upload.destroy_for_account(@checking) }.
          should change { @txfer.reload.paired_transfer? }.from(true).to(false)
      end
    end

    describe "being cleared for a single account" do
      describe "associated with only one account" do
        it_should_behave_like "an Upload with any number of accounts"

        it "deletes the upload file" do
          lambda { @upload.destroy_for_account(@checking) }.
            should change { @upload.filepath.exist? }.from(true).to(false)
        end
      end

      describe "associated with multiple accounts" do
        before do
          AccountUpload.create(:upload => @upload, :account => @savings)
        end

        it_should_behave_like "an Upload with any number of accounts"

        it "does not delete the upload file" do
          lambda { @upload.destroy_for_account(@checking) }.
            should_not change { @upload.filepath.exist? }.from(true).to(false)
        end
      end
    end

    after do
      FileUtils.rm_f(@upload.filepath)
    end
  end
end

if defined?(OFX_CONVERTER) && File.executable?(OFX_CONVERTER.split(/\s/).first)
  describe Upload, ".generate" do
    # make sure temp statement dir exists
    before do
      @old_statement_path = ApiEnv::PATH[:statement_files]
      ApiEnv::PATH[:statement_files] = '/tmp/upload_test'
      FileUtils.makedirs(ApiEnv::PATH[:statement_files])

      @account = Account.make
      @user = @account.user
    end

    # remove temp statement dir
    after do
      FileUtils.rmtree(ApiEnv::PATH[:statement_files])
      ApiEnv::PATH[:statement_files] = @old_statement_path
    end

    it "handles OFX files" do
      statement = fixture_file_upload('files/statement.OFX').read
      user_dir = Upload.statement_dir(@user.account_key)
      upload = Upload.generate(:user => @user,
                             :statement => statement,
                             :account => @account,
                             :client_name => 'UploadTest',
                             :client_version => '1.0',
                             :client_platform => ClientPlatform.find_or_create_by_name('test-platform'))

      upload.should_not be_a_new_record
      upload.converted_statement.should_not be_nil
      upload.original_format.should match(/OFX/)
      user_dir.should exist
      user_dir.should have(1).child
    end

    it "handles OFC files" do
      statement = fixture_file_upload('files/statement.OFC').read
      user_dir = Upload.statement_dir(@user.account_key)
      upload = Upload.generate(:user => @user,
                             :statement => statement,
                             :account => @account,
                             :client_name => 'UploadTest',
                             :client_version => '1.0',
                             :client_platform => ClientPlatform.find_or_create_by_name('test-platform'))

      upload.should_not be_a_new_record
      upload.converted_statement.should_not be_nil
      upload.original_format.should match(/OFC/)
      user_dir.should exist
      user_dir.should have(1).child
    end

    it "handles QIF files" do
      statement = fixture_file_upload('files/statement.QIF').read
      user_dir = Upload.statement_dir(@user.account_key)
      upload = Upload.generate(:user => @user,
                             :statement => statement,
                             :account => @account,
                             :balance => 1234.56,
                             :client_name => 'UploadTest',
                             :client_version => '1.0',
                             :client_platform => ClientPlatform.find_or_create_by_name('test-platform'))

      upload.should_not be_a_new_record
      upload.converted_statement.should_not be_nil
      upload.original_format.should match(/QIF/)
      user_dir.should exist
      user_dir.should have(1).child
    end

    it "raises an exception on blank file upload" do
      statement = ''
      user_dir = Upload.statement_dir(@user.account_key)

      lambda do
        Upload.generate(:user => @user,
          :statement => statement,
          :account => @account,
          :client_name => 'UploadTest',
          :client_version => '1.0',
          :client_platform => ClientPlatform.find_or_create_by_name('test-platform'))
      end.should raise_error(MakeOFX2::NoInputError)

      user_dir.should exist
      user_dir.should have(1).child
    end

    it "raises an exception on PDF upload" do
      statement = fixture_file_upload('files/test.pdf').read
      user_dir = Upload.statement_dir(@user.account_key)

      lambda do
        Upload.generate(:user => @user,
          :statement => statement,
          :account => @account,
          :client_name => 'UploadTest',
          :client_version => '1.0',
          :client_platform => ClientPlatform.find_or_create_by_name('test-platform'))
      end.should raise_error(MakeOFX2::UnsupportedFormatError)

      user_dir.should exist
      user_dir.should have(1).child
    end

    it "raises an exception on CSV upload" do
      statement = fixture_file_upload('files/test.csv').read
      user_dir = Upload.statement_dir(@user.account_key)

      lambda do
        Upload.generate(:user => @user,
          :statement => statement,
          :account => @account,
          :client_name => 'UploadTest',
          :client_version => '1.0',
          :client_platform => ClientPlatform.find_or_create_by_name('test-platform'))
      end.should raise_error(MakeOFX2::UnsupportedFormatError)

      user_dir.should exist
      user_dir.should have(1).child
    end
  end
else
  print "(ofx converter not installed -- skipping tests)"
end