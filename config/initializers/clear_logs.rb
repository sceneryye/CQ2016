# # config/initializers/clear_logs.rb
# if Rails.env.development?
#   MAX_LOG_SIZE = 2.megabytes

#   logs = [ File.join(Rails.root, 'log', 'development.log'), File.join(Rails.root, 'log', 'test.log') ]

#   logs.each do |log|
#     if File.size?(log).to_i > MAX_LOG_SIZE
#       $stdout.puts "Removing Log: #{log}"
#       `rm #{log}`
#     end
#   end
# end