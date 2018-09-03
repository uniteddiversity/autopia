class HabitCompletionLike
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account
  belongs_to :habit_completion
    
  validates_presence_of :account, :habit_completion
  validates_uniqueness_of :account, :scope => :habit_completion
          
  def self.admin_fields
    {
      :account_id => :lookup,
      :habit_completion_id => :lookup
    }
  end
  
  after_create :send_like
  def send_like
    if ENV['SMTP_ADDRESS']
      habit_completion_like = self
      habit_completion = habit_completion_like.habit_completion
      habit = habit_completion.habit

      unless habit_completion.account.unsubscribed?
        mail = Mail.new
        mail.to = habit_completion.account.email
        mail.from = ENV['NOTIFICATION_EMAIL']
        mail.subject = "#{habit_completion_like.account.name} liked your completion of #{habit.name}"
            
        content = ERB.new(File.read(Padrino.root('app/views/emails/habit_completion_like.erb'))).result(binding)
        html_part = Mail::Part.new do
          content_type 'text/html; charset=UTF-8'
          body ERB.new(File.read(Padrino.root('app/views/layouts/email.erb'))).result(binding)
        end
        mail.html_part = html_part
      
        mail.deliver
      end
    end    
  end
  handle_asynchronously :send_like
    
end
