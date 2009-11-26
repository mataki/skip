Group.all(:conditions => { :protected => false }).each do |group|
  group.group_participations.waiting.each do |p|
    p.update_attributes(:waiting => false)
    puts "Updated id: #{p.id} on #{group.id}"
  end
end
