module QuotaValidation
  def valid_size_of_file(file)
    if file.size == 0
      errors.add_to_base "存在しないもしくはサイズ０のファイルはアップロードできません。"
    elsif file.size > SkipEmbedded::InitialSettings['max_share_file_size'].to_i
      errors.add_to_base "#{SkipEmbedded::InitialSettings['max_share_file_size'].to_i/1.megabyte}Mバイト以上のファイルはアップロードできません。"
    end
  end

  def valid_max_size_per_owner_of_file(file, owner_symbol)
    if (FileSizeCounter.per_owner(owner_symbol) + file.size) > SkipEmbedded::InitialSettings['max_share_file_size_per_owner'].to_i
      errors.add_to_base "ファイル保存領域の利用容量が最大値を越えてしまうためアップロードできません。"
    end
  end

  def valid_max_size_of_system_of_file(file)
    if (FileSizeCounter.per_system + file.size) > SkipEmbedded::InitialSettings['max_share_file_size_of_system'].to_i
      errors.add_to_base "システム全体におけるファイル保存領域の利用容量が最大値を越えてしまうためアップロードできません。"
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


