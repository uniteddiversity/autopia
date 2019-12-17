Autopia::App.helpers do

  def mass_assigning(params, model)
    params ||= {}
    if model.respond_to?(:protected_attributes)
      intersection = model.protected_attributes & params.keys
      if !intersection.empty?
        raise "attributes #{intersection} are protected"
      end
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
  
  def organisation_admin?(organisation=nil, account=current_account)
    organisation = @organisation if !organisation
    account && (organisation.account_id == account.id || organisation.organisationships.find_by(account: account, admin: true) || account.admin?)
  end  
  
  def organisation_admins_only!(organisation=nil, account=current_account)
    organisation = @organisation if !organisation
    unless organisation_admin?(organisation, account)
      flash[:notice] = 'You must be a team member of that organisation to access that page'
      session[:return_to] = request.url
      request.xhr? ? halt(403) : redirect(account ? '/' : '/accounts/sign_in')      
    end
  end
  
  def activity_admin?(activity=nil, account=current_account)
    activity = @activity if !activity
    activity.activityships.find_by(account: account, admin: true) || organisation_admin?(activity.organisation, account)
  end  
  
  def activity_admins_only!(activity=nil, account=current_account)
    activity = @activity if !activity
    unless activity_admin?(activity, account)
      flash[:notice] = 'You must be an admin of that activity to access that page'
      session[:return_to] = request.url
      request.xhr? ? halt(403) : redirect(account ? '/' : '/accounts/sign_in')      
    end    
  end  
  
  
  def local_group_admin?(local_group=nil, account=current_account)
    local_group = @local_group if !local_group
    local_group.local_groupships.find_by(account: account, admin: true) || organisation_admin?(local_group.organisation, account)
  end  
  
  def local_group_admins_only!(local_group=nil, account=current_account)
    local_group = @local_group if !local_group
    unless local_group_admin?(local_group, account)
      flash[:notice] = 'You must be an admin of that local group to access that page'
      session[:return_to] = request.url
      request.xhr? ? halt(403) : redirect(account ? '/' : '/accounts/sign_in')      
    end    
  end  
  
  def event_admin?(event=nil, account=current_account)
    event = @event if !event
    account && (event.account_id == account.id || event.revenue_sharer_id == account.id || event.event_facilitations.find_by(account: account) || (event.activity && activity_admin?(event.activity, account)) || (event.organisation && organisation_admin?(event.organisation, account)) || account.admin?)
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
    unless account and gathering and gathering.memberships.find_by(account: account)
      flash[:notice] = 'You must be a member of that gathering to access that page'
      session[:return_to] = request.url
      request.xhr? ? halt(403) : redirect(account ? '/' : '/accounts/sign_in')
    end
  end

  def confirmed_membership_required!(gathering=nil, account=current_account)
    gathering = @gathering if !gathering
    unless account and gathering and ((membership = gathering.memberships.find_by(account: account)) and membership.confirmed?)
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
