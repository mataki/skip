class Ranking < ActiveRecord::Base
  def add_amount(amount)
    return false unless (amount.class == Fixnum && amount > 0)
    self.amount += amount
    save
  end 
end
