class HabitCompletionLike
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
  belongs_to :habit_completion, index: true
    
  validates_presence_of :account, :habit_completion
  validates_uniqueness_of :account, :scope => :habit_completion
          
  def self.admin_fields
    {
      :account_id => :lookup,
      :habit_completion_id => :lookup
    }
  end
  
  def habit
    habit_completion.habit
  end
         
  after_create :send_like
  def send_like
    if !habit_completion.account.unsubscribed? && !habit_completion.account.unsubscribed_habit_completion_likes?      
      mg_client = Mailgun::Client.new ENV['MAILGUN_API_KEY']
      batch_message = Mailgun::BatchMessage.new(mg_client, ENV['MAILGUN_DOMAIN'])
    
      habit_completion_like = self
      habit_completion = habit_completion_like.habit_completion
      habit = habit_completion.habit
      content = ERB.new(File.read(Padrino.root('app/views/emails/habit_completion_like.erb'))).result(binding)
      batch_message.from ENV['NOTIFICATION_EMAIL']
      batch_message.subject "#{habit_completion_like.account.name} liked your completion of #{habit.name} on #{habit_completion.date}"
      batch_message.body_html ERB.new(File.read(Padrino.root('app/views/layouts/email.erb'))).result(binding)
                
      [habit_completion.account].each { |account|
        batch_message.add_recipient(:to, account.email, {'firstname' => (account.firstname || 'there'), 'token' => account.sign_in_token, 'id' => account.id})
      }      

      batch_message.finalize
    end    
  end
  handle_asynchronously :send_like
    
end
