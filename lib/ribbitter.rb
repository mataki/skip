
class Ribbitter
  class << self
    def messages(uid)
      attr = %w(id from title time body)
      arr = []
      20.times do |i|
        arr << { :id => "111#{i}", :from => "from", :title => "#{i}:#{title_rand}", :time => Time.local(2009,10,3), :body => "#{i}:#{body_rand}" }
      end
      arr
    end

    def call_history(uid)
      attr = %w(id from title time body)
      arr = []
      20.times do |i|
        arr << { :id => "111#{i}", :name => "name", :number => "#{i}:#{title_rand}", :time => Time.local(2009,10,3) }
      end
      arr
    end

    def title_rand
      %w(こんにちわ さようなら おわかれ はじめまして).rand
    end

    def body_rand
      %w(ああああああああああああああああああああああああああああああああああ いいいいいいいいいいいいいいいいいいいいいいいいいいいいいい ううううううううううううううううううう おおおおおおおおおおおおおおおおおおおおおお いおいおいおいおいおいいいおいおいおいおいいおういおういおうおい ういうおういおうおいういおういおうおういおういおう).rand
    end
  end
end
