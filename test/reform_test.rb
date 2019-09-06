require "test_helper"
require "reform"
require "reform/rails"

describe Shrine::Plugins::Reform do
  before do
    @uploader = uploader do
      plugin :activerecord
      plugin :reform
    end

    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    ActiveRecord::Base.connection.create_table(:records) do |t|
      t.text :attachment_data
    end
    ActiveRecord::Base.connection.create_table(:nested_records) do |t|
      t.integer :record_id
      t.text :attachment_data
    end

    record_class = Object.const_set("Record", Class.new(ActiveRecord::Base))
    record_class.table_name = :records
    record_class.include @uploader.class::Attachment.new(:attachment)
    record_class.has_many :nested_records

    nested_class = Object.const_set("NestedRecord", Class.new(ActiveRecord::Base))
    nested_class.table_name = :nested_records
    nested_class.include @uploader.class::Attachment.new(:attachment)
    nested_class.belongs_to :record

    nested_form_class = Class.new(Reform::Form)
    nested_form_class.include @uploader.class::Attachment.new(:attachment)

    form_class = Class.new(Reform::Form)
    form_class.include @uploader.class::Attachment.new(:attachment)
    form_class.collection :nested_records, populate_if_empty: NestedRecord, form: nested_form_class

    @record = record_class.new
    @form = form_class.new(@record)
  end

  after do
    ActiveRecord::Base.remove_connection
    Object.send(:remove_const, "Record")
    Object.send(:remove_const, "NestedRecord")
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

    @form.validate(nested_records: [{attachment: StringIO.new}])
    assert_kind_of Shrine::UploadedFile, @form.nested_records[0].attachment
  end

  it "merges attachment validations" do
    @record.attachment_attacher.class.validate { errors << "Error" }

    @form.validate(attachment: StringIO.new)
    assert_equal ["Error"], @form.errors[:attachment]

    @form.validate(nested_records: [{attachment: StringIO.new}])
    assert_equal ["Error"], @form.errors["nested_records.attachment"]
  end

  it "syncs attachment" do
    @form.validate(attachment: StringIO.new)
    @form.sync
    assert_kind_of Shrine::UploadedFile, @record.attachment

    @form.validate(nested_records: [{attachment: StringIO.new}])
    @form.sync
    assert_kind_of Shrine::UploadedFile, @record.nested_records[0].attachment
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
    assert_nil @record.attachment
  end

  it "doesn't sync attachment that hasn't changed" do
    @record.attachment_data = @record.attachment_attacher.cache!(StringIO.new).to_json
    @form.prepopulate!
    @form.sync
    refute @record.attachment_attacher.attached?
  end

  it "doesn't sync when model doesn't have attachment module" do
    @record.instance_eval { undef attachment= }
    @form.attachment = StringIO.new
    @form.sync

    assert_nil @record.attachment_data
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
