module QuotaValidation
  include GetText
  def valid_size_of_file(file)
    if file.size == 0
      errors.add_to_base _("Nonexistent or empty files are not accepted for uploading.")
    elsif file.size > SkipEmbedded::InitialSettings['max_share_file_size'].to_i
      errors.add_to_base _("Files larger than %sMBytes are not permitted.") % (SkipEmbedded::InitialSettings['max_share_file_size'].to_i / 1.megabyte)
    end
  end

  def valid_max_size_of_system_of_file(file)
    if (FileSizeCounter.per_system + file.size) > SkipEmbedded::InitialSettings['max_share_file_size_of_system'].to_i
      errors.add_to_base _("Upload denied due to excess of system wide shared files disk capacity.")
    end
  end

  class FileSizeCounter
    def self.per_owner owner_symbol
      sum = 0
      sum += ShareFile.total_share_file_size(owner_symbol)
      sum
    end
    def self.per_system
      sum = 0
      Dir.glob("#{SkipEmbedded::InitialSettings['share_file_path']}/**/*").each do |f|
        sum += File.stat(f).size
      end
      sum
    end
  end
end

