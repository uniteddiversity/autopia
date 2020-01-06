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

  def random(relation, n)
    count = relation.count
    (0..count-1).sort_by{rand}.slice(0, n).collect! do |i| relation.skip(i).first end
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
  
  
    
  def kick!
    flash[:notice] = "You don't have access to that page"
    session[:return_to] = request.url
    request.xhr? ? halt(403) : redirect(current_account ? '/' : '/accounts/sign_in')          
  end
  
  def creator?(createable, account=current_account)
    account and createable.account and createable.account.id == account.id
  end  
  
  def admin?(account=current_account)
    account && account.admin?
  end  
  def admins_only!; kick! unless admin?; end
  
  def organisation_admin?(organisation=nil, account=current_account)
    organisation = @organisation if !organisation
    account && organisation && (organisation.account_id == account.id || organisation.organisationships.find_by(account: account, admin: true) || account.admin?)
  end    
  def organisation_admins_only!; kick! unless organisation_admin?; end  
    
  def activity_admin?(activity=nil, account=current_account)
    activity = @activity if !activity
    account && activity && activity.activityships.find_by(account: account, admin: true) || organisation_admin?(activity.organisation, account)
  end  
  def activity_admins_only!; kick! unless activity_admin?; end  
    
  def local_group_admin?(local_group=nil, account=current_account)
    local_group = @local_group if !local_group
    account && local_group && local_group.local_groupships.find_by(account: account, admin: true) || organisation_admin?(local_group.organisation, account)
  end  
  def local_group_admins_only!; kick! unless local_group_admin?; end  
  
  def organisation_assistant?(organisation=nil, account=current_account)
    organisation = @organisation if !organisation
    account && organisation && organisation_admin?(organisation, account) or organisation.local_groups.any? { |local_group| local_group_admin?(local_group, account) } or organisation.activities.any? { |activity| activity_admin?(activity, account) }
  end  
  def organisation_assistants_only!; kick! unless organisation_assistant?; end  
    
  def event_admin?(event=nil, account=current_account)
    event = @event if !event
    account && event && (event.account_id == account.id || event.revenue_sharer_id == account.id || event.event_facilitations.find_by(account: account) || (event.activity && activity_admin?(event.activity, account)) || (event.organisation && organisation_admin?(event.organisation, account)) || account.admin?)
  end  
  def event_admins_only!; kick! unless event_admin?; end  
  
  def event_participant?(event=nil, account=current_account)
    event = @event if !event
    (account && event.tickets.find_by(account: current_account)) || event_admin?(event, account)
  end
  def event_participants_only!; kick! unless event_participant?; end
  
  def gathering_admin?(gathering=nil, account=current_account)
    gathering = @gathering if !gathering
    account && gathering and ((membership = gathering.memberships.find_by(account: account)) and membership.admin?)
  end
  def gathering_admins_only!; kick! unless gathering_admin?; end  
  
  def pmailer?(pmail=nil, account=current_account)
    pmail = @pmail if !pmail
    account && pmail && (organisation_admin?(pmail.organisation) || (pmail.mailable.is_a?(Activity) && activity_admin?(pmail.mailable)) || (pmail.mailable.is_a?(LocalGroup) && local_group_admin?(pmail.mailable)))
  end
  def pmailers_only!; kick! unless pmailer?; end
  
  
  
  
  def sign_in_required!
    unless current_account
      flash[:notice] = 'You must sign in to access that page'
      session[:return_to] = request.url
      request.xhr? ? halt : redirect('/accounts/sign_in')
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
  
end
