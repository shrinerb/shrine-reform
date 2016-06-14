require "test_helper"
require "active_record"
require "reform"
require "reform/rails"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.connection.create_table(:records) { |t| t.text :attachment_data }
ActiveRecord::Base.raise_in_transactional_callbacks = true

describe Shrine::Plugins::Reform do
  before do
    @uploader = uploader do
      plugin :activerecord
      plugin :reform
    end

    record_class = Object.const_set("Record", Class.new(ActiveRecord::Base))
    record_class.table_name = :records
    record_class.include @uploader.class[:attachment]

    form_class = Class.new(Reform::Form)
    form_class.include @uploader.class[:attachment]

    @record = record_class.new
    @form = form_class.new(@record)
  end

  after do
    @record.class.delete_all
    Object.send(:remove_const, "Record")
  end

  it "prepopulates attachment" do
    @record.attachment = StringIO.new
    @form.prepopulate!
    assert_kind_of Shrine::UploadedFile, @form.attachment
  end

  it "doesn't error when there is nothing to prepopulate" do
    @form.prepopulate!
  end

  it "populates attachment" do
    @form.validate(attachment: StringIO.new)
    assert_kind_of Shrine::UploadedFile, @form.attachment
  end

  it "merges attachment validations" do
    @record.attachment_attacher.class.validate { errors << "Error" }
    @form.validate(attachment: StringIO.new)
    assert_equal ["Error"], @form.errors[:attachment]
  end

  it "syncs attachment" do
    @form.validate(attachment: StringIO.new)
    @form.sync
    assert_kind_of Shrine::UploadedFile, @record.attachment
  end

  it "doesn't sync when attachment wasn't set" do
    @record.attachment = StringIO.new
    @form.sync
    assert_kind_of Shrine::UploadedFile, @record.attachment
  end

  it "syncs attachment removal" do
    @record.attachment = StringIO.new
    @form.prepopulate!
    @form.validate(attachment: nil)
    @form.sync
    assert_equal nil, @record.attachment
  end

  it "doesn't sync attachment that hasn't changed" do
    @record.attachment_data = @record.attachment_attacher.cache.upload(StringIO.new).to_json
    @form.prepopulate!
    @form.sync
    refute @record.attachment_attacher.attached?
  end

  it "detects remote_url plugin" do
    refute_respond_to @form, :attachment_remote_url
    @uploader.class.plugin :remote_url, max_size: nil
    @form.class.prepend @uploader.class[:attachment]
    assert_respond_to @form, :attachment_remote_url
  end

  it "detects data_uri plugin" do
    refute_respond_to @form, :attachment_data_uri
    @uploader.class.plugin :data_uri
    @form.class.prepend @uploader.class[:attachment]
    assert_respond_to @form, :attachment_data_uri
  end

  it "detects remote_attachment plugin" do
    refute_respond_to @form, :remove_attachment
    @uploader.class.plugin :remove_attachment
    @form.class.prepend @uploader.class[:attachment]
    assert_respond_to @form, :remove_attachment
  end

  it "detects cached_attachment_data plugin" do
    refute_respond_to @form, :cached_attachment_data
    @uploader.class.plugin :cached_attachment_data
    @form.class.prepend @uploader.class[:attachment]
    assert_respond_to @form, :cached_attachment_data
  end

  it "doesn't define any Reform methods on non-Reform objects" do
    refute_respond_to @record, :prepopulate!
    refute_respond_to @record, :sync
  end
end
