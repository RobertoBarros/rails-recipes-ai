class FakeJob < ApplicationJob
  queue_as :default

  def perform
    puts "I'm starting the fake job"
    sleep 10
    puts "OK I'm done now"
  end
end
