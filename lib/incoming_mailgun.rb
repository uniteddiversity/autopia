class EmailReceiver < Incoming::Strategies::Mailgun
	setup :api_key => ENV['MAILGUN_API_KEY']
  def receive(mail)
    raise request.inspect
  end
end