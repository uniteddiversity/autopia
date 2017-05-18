class EmailReceiver < Incoming::Strategies::Mailgun
  def receive(mail)
    raise mail.inspect
  end
end