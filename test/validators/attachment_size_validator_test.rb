require './test/helper'

class AttachmentSizeValidatorTest < Test::Unit::TestCase
  def setup
    rebuild_model
    @dummy = Dummy.new
  end

  def build_validator(options)
    @validator = Paperclip::Validators::AttachmentSizeValidator.new(options.merge(
      :attributes => :avatar_file_size
    ))
  end

  def self.should_allow_attachment_file_size(size)
    context "when the attachment size is #{size}" do
      should "add error to dummy object" do
        @dummy.stubs(:avatar_file_size).returns(size)
        @validator.validate(@dummy)
        assert @dummy.errors[:avatar_file_size].blank?,
          "Expect an error message on :avatar_file_size, got none."
      end
    end
  end

  def self.should_not_allow_attachment_file_size(size)
    context "when the attachment size is #{size}" do
      should "add error to dummy object" do
        @dummy.stubs(:avatar_file_size).returns(size)
        @validator.validate(@dummy)
        assert @dummy.errors[:avatar_file_size].present?,
          "Unexpected error message on :avatar_file_size"
      end
    end
  end

  context "with :in option" do
    context "as a range" do
      setup do
        build_validator :in => (5.kilobytes..10.kilobytes)
      end

      should_allow_attachment_file_size(7.kilobytes)
      should_not_allow_attachment_file_size(4.kilobytes)
      should_not_allow_attachment_file_size(11.kilobytes)
    end

    context "as a proc" do
      setup do
        build_validator :in => lambda { |avatar| (5.kilobytes..10.kilobytes) }
      end

      should_allow_attachment_file_size(7.kilobytes)
      should_not_allow_attachment_file_size(4.kilobytes)
      should_not_allow_attachment_file_size(11.kilobytes)
    end
  end

  context "with :greater_than option" do
    setup do
      build_validator :greater_than => 10.kilobytes
    end

    should_allow_attachment_file_size 11.kilobytes
    should_not_allow_attachment_file_size 10.kilobytes
  end

  context "with :less_than option" do
    setup do
      build_validator :less_than => 10.kilobytes
    end

    should_allow_attachment_file_size 9.kilobytes
    should_not_allow_attachment_file_size 10.kilobytes
  end

  context "with :greater_than and :less_than option" do
    setup do
      build_validator :greater_than => 5.kilobytes, :less_than => 10.kilobytes
    end

    should_allow_attachment_file_size 7.kilobytes
    should_not_allow_attachment_file_size 5.kilobytes
    should_not_allow_attachment_file_size 10.kilobytes
  end

  context "with :message option" do
    context "given a range" do
      setup do
        @validator = Paperclip::Validators::AttachmentSizeValidator.new(
          :attributes => :avatar_file_size,
          :in => (5.kilobytes..10.kilobytes),
          :message => "is invalid. (Between %{min} and %{max} please.)"
        )
      end

      should "return a correct message" do
        @dummy.stubs(:avatar_file_size).returns(11.kilobytes)
        @validator.validate(@dummy)
        assert_include @dummy.errors[:avatar_file_size], "is invalid. (Between 5120 Bytes and 10240 Bytes please.)"
      end
    end

    context "given :less_than and :greater_than" do
      setup do
        @validator = Paperclip::Validators::AttachmentSizeValidator.new(
          :attributes => :avatar_file_size,
          :less_than => 10.kilobytes,
          :greater_than => 5.kilobytes,
          :message => "is invalid. (Between %{min} and %{max} please.)"
        )
      end

      should "return a correct message" do
        @dummy.stubs(:avatar_file_size).returns(11.kilobytes)
        @validator.validate(@dummy)
        assert_include @dummy.errors[:avatar_file_size], "is invalid. (Between 5120 Bytes and 10240 Bytes please.)"
      end
    end
  end

  context "default error messages" do
    context "given :less_than and :greater_than" do
      setup do
        @validator = Paperclip::Validators::AttachmentSizeValidator.new(
          :attributes => :avatar_file_size,
          :greater_than => 5.kilobytes,
          :less_than => 10.kilobytes
        )
      end

      context "for file that is too large" do
        should "return a correct message" do
          @dummy.stubs(:avatar_file_size).returns(11.kilobytes)
          @validator.validate(@dummy)
          assert_include @dummy.errors[:avatar_file_size], "must be less than 10240 Bytes"
        end
      end

      context "for file that is too small" do
        should "return a correct message" do
          @dummy.stubs(:avatar_file_size).returns(4.kilobytes)
          @validator.validate(@dummy)
          assert_include @dummy.errors[:avatar_file_size], "must be greater than 5120 Bytes"
        end
      end
    end
    context "given a size range" do
      setup do
        @validator = Paperclip::Validators::AttachmentSizeValidator.new(
          :attributes => :avatar_file_size,
          :in => (5.kilobytes..10.kilobytes)
        )
      end

      context "for file that is too large" do
        should "return a correct message" do
          @dummy.stubs(:avatar_file_size).returns(11.kilobytes)
          @validator.validate(@dummy)
          assert_include @dummy.errors[:avatar_file_size], "must be in between 5120 Bytes and 10240 Bytes"
        end
      end

      context "for file that is too small" do
        should "return a correct message" do
          @dummy.stubs(:avatar_file_size).returns(4.kilobytes)
          @validator.validate(@dummy)
          assert_include @dummy.errors[:avatar_file_size], "must be in between 5120 Bytes and 10240 Bytes"
        end
      end
    end
  end
end
