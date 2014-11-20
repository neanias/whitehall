puts "Pushing case studies to publishing API"
CaseStudy.find_each do |case_study|
  print '.'
  PublishingApiEditionWorker.perform_async(case_study.id)
end
puts "\n#{CaseStudy.count} case studies queued for pushing to the publishing API"
