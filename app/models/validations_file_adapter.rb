require 'forwardable'
class ValidationsFileAdapter
  extend Forwardable
  def initialize(record)
    @record = record
  end

  def_delegators :@record, :content_type, :size

  def original_filename
    @record.display_name
  end
end
