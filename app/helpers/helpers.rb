Autopia::App.helpers do

  def mass_assigning(params, model)
    params ||= {}
    intersection = model.protected_attributes & params.keys
    if !intersection.empty?
      raise "attributes #{intersection} are protected"
    end
    params
  end

  def current_account
    @current_account ||= Account.find(session[:account_id]) if session[:account_id]
  end

  def admin?
    current_account && current_account.admin?
  end

  def creator?(createable)
    current_account and createable.account and createable.account.id == current_account.id
  end  

  def random(relation, n)
    count = relation.count
    (0..count-1).sort_by{rand}.slice(0, n).collect! do |i| relation.skip(i).first end
  end

  def sign_in_required!
    unless current_account
      flash[:notice] = 'You must sign in to access that page'
      session[:return_to] = request.url
      request.xhr? ? halt : redirect('/accounts/sign_in')
    end
  end

  def timeago(x)
    %Q{<abbr class="timeago" title="#{x.iso8601}">#{x}</abbr>}
  end

  def f(slug)
    (if fragment = Fragment.find_by(slug: slug) and fragment.body
        "\"#{fragment.body.to_s.gsub('"','\"')}\""
      end).to_s
  end

  def discuss(name)
    @feature = Feature.find_by(name: name) || Feature.create(name: name)
  end
  
  def promoter_admin?(promoter=nil, account=current_account)
    promoter = @promoter if !promoter
    account && (promoter.account_id == account.id || promoter.promotercrowns.find_by(account: account) || account.admin?)
  end  
  
  def promoter_admins_only!(promoter=nil, account=current_account)
    promoter = @promoter if !promoter
    unless promoter_admin?(promoter, account)
      flash[:notice] = 'You must be a team member of that promoter to access that page'
      session[:return_to] = request.url
      request.xhr? ? halt(403) : redirect(account ? '/' : '/accounts/sign_in')      
    end
  end
  
  def activity_admin?(activity=nil, account=current_account)
    activity = @activity if !activity
    promoter_admin?(activity.promoter)
  end  
  
  def activity_admins_only!(activity=nil, account=current_account)
    activity = @activity if !activity
    promoter_admins_only!(activity.promoter)
  end  
  
  def event_admin?(event=nil, account=current_account)
    event = @event if !event
    account && (event.account_id == account.id || (event.promoter && promoter_admin?(event.promoter, account)) || account.admin?)
  end  
  
  def event_admins_only!(event=nil, account=current_account)
    event = @event if !event
    unless event_admin?(event, account)
      flash[:notice] = 'You must be an admin of that event to access that page'
      session[:return_to] = request.url
      request.xhr? ? halt(403) : redirect(account ? '/' : '/accounts/sign_in')      
    end
  end

  def membership_required!(gathering=nil, account=current_account)
    gathering = @gathering if !gathering
    unless account and gathering and (gathering.memberships.find_by(account: account) or account.admin?)
      flash[:notice] = 'You must be a member of that gathering to access that page'
      session[:return_to] = request.url
      request.xhr? ? halt(403) : redirect(account ? '/' : '/accounts/sign_in')
    end
  end

  def confirmed_membership_required!(gathering=nil, account=current_account)
    gathering = @gathering if !gathering
    unless account and gathering and (((membership = gathering.memberships.find_by(account: account)) and membership.confirmed?) or account.admin?)
      session[:return_to] = request.url
      if membership
        flash[:notice] = 'You must make a payment before accessing that page'
        request.xhr? ? halt(403) : redirect("/a/#{@gathering.slug}")
      else
        flash[:notice] = 'You must be a member of the gathering to access that page'
        request.xhr? ? halt(403) : redirect(account ? '/' : '/accounts/sign_in')
      end
    end
  end

  def admins_only!
    unless current_account and current_account.admin?
      flash[:notice] = 'You must be an admin to access that page'
      session[:return_to] = request.url
      request.xhr? ? halt(403) : redirect(current_account ? '/' : '/accounts/sign_in')
    end
  end

  def gathering_admins_only!(gathering=nil)
    gathering = @gathering if !gathering
    unless current_account and gathering and ((membership = gathering.memberships.find_by(account: current_account)) and membership.admin?)
      flash[:notice] = 'You must be an admin of that gathering to access that page'
      session[:return_to] = request.url
      request.xhr? ? halt(403) : redirect(current_account ? '/' : '/accounts/sign_in')
    end
  end

end
