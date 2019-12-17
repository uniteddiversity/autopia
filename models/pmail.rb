class Pmail
  include Mongoid::Document
  include Mongoid::Timestamps
    
  field :from, :type => String  
  field :subject, :type => String
  field :body, :type => String
  field :no_layout, :type => Boolean  
  field :message_ids, :type => String
  field :sent_at, :type => ActiveSupport::TimeWithZone  
  
  belongs_to :organisation, index: true
  belongs_to :account, index: true
  
  belongs_to :mailable, polymorphic: true, index: true, optional: true
  
  def self.mailable_types
    %w{Activity LocalGroup}
  end 
  
  validates_presence_of :from, :subject, :body
  validates_format_of :from, :with => /.* <.*>/
  
  attr_accessor :file, :to_option  
  
  def to_selected
    if mailable.is_a?(Activity)
      "activity:#{mailable_id}"
    elsif mailable.is_a?(LocalGroup)
      "local_group:#{mailable_id}"
    else
      'all'
    end        
  end  
  
  def to
    if mailable
      mailable.subscribed_members
    else
      organisation.subscribed_members
    end
  end  
  
  def to_with_unsubscribes
    to.where(:id.nin => organisation.unsubscribed_members.pluck(:id)).where(:unsubscribed.ne => true)
  end
  
  before_validation do  
    
    if to_option.starts_with?('activity:')
      self.mailable_type = 'Activity'
      self.mailable_id = to_option.split(':').last
    elsif to_option.starts_with?('local_group')
      self.mailable_type = 'LocalGroup'
      self.mailable_id = to_option.split(':').last
    else
      self.mailable = nil
    end
    
  end
  
  after_save do    
    organisation.attachments.create(file: file) if file
  end
          
  def self.admin_fields
    {
      :from => :text,
      :subject => :text,
      :body => :text_area,
      :no_layout => :check_box,
      :sent_at => :datetime,
      :message_ids => :text_area,
      :account_id => :lookup
    }
  end
                   
  def send_pmail
    if !sent_at
      message_ids = send_batch_message(to)
      update_attribute(:sent_at, Time.now)
      update_attribute(:message_ids, message_ids)
    end
  end
  handle_asynchronously :send_pmail
  
  def send_test(account)     
    send_batch_message Account.where(:id.in => [account.id]), test_message: true
  end
  
  def self.layout(pmail)
    ERB.new(File.read(Padrino.root('app/views/layouts/mailer.erb'))).result(binding)
  end  
  
  def send_batch_message(to, test_message: false)
    mg_client = Mailgun::Client.new ENV['MAILGUN_API_KEY']
    batch_message = Mailgun::BatchMessage.new(mg_client, ENV['MAILGUN_DOMAIN'])
              
    batch_message.from from  
    batch_message.subject (test_message ? "#{subject} [test sent #{Time.now}]" : subject)
    batch_message.body_html Pmail.layout(self)
    batch_message.add_tag id
        
    (test_message ? to : to_with_unsubscribes).each { |account|
      batch_message.add_recipient(:to, account.email, {'firstname' => (account.firstname || 'there'), 'token' => account.sign_in_token, 'id' => account.id, 'username' => account.username})
    }
        
    batch_message.finalize    
  end  
       
  def self.new_hints
    {
      :from => 'In the form <em>Joe Blogs &lt;joe.bloggs@psychedelicsociety.org.uk&gt;</em>'
    }
  end  
  
  def self.edit_hints
    self.new_hints
  end     
      
  def self.send_html_email(to,from,subject,body, bcc: nil)
    return if !ENV['SMTP_USERNAME']
    mail = Mail.new
    mail.to = to
    mail.from = from
    mail.bcc = bcc if bcc
    mail.subject = subject
      
    html_part = Mail::Part.new do
      content_type 'text/html; charset=UTF-8'
      body body
    end

    mail.html_part = html_part                 
    mail.deliver    
  end
       
  def self.human_attribute_name(attr, options = {})
    {
      to_option: 'To',
    }[attr.to_sym] || super
  end
  
end