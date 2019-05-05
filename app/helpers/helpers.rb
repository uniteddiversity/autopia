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
  
  def membership_required!(group=nil, account=current_account)
    group = @group if !group
    unless account and group and (group.memberships.find_by(account: account) or account.admin?)
      flash[:notice] = 'You must be a member of that group to access that page'
      session[:return_to] = request.url
      request.xhr? ? halt(403) : redirect(account ? '/' : '/accounts/sign_in')
    end            
  end        
    
  def confirmed_membership_required!(group=nil, account=current_account)
    group = @group if !group
    unless account and group and (((membership = group.memberships.find_by(account: account)) and membership.confirmed?) or account.admin?)
      session[:return_to] = request.url
      if membership
        flash[:notice] = 'You must make a payment before accessing that page'
        request.xhr? ? halt(403) : redirect("/a/#{@group.slug}")
      else
        flash[:notice] = 'You must be a member of the group to access that page'
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
  
  def group_admins_only!(group=nil)
    group = @group if !group
    unless current_account and group and ((membership = group.memberships.find_by(account: current_account)) and membership.admin?)
      flash[:notice] = 'You must be an admin of that group to access that page'
      session[:return_to] = request.url
      request.xhr? ? halt(403) : redirect(current_account ? '/' : '/accounts/sign_in')
    end        
  end    
  
end