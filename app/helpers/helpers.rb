Cocreately::App.helpers do
  
  def current_account
    @current_account ||= Account.find(session[:account_id]) if session[:account_id]
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
  
  def membership_required!(group=nil, account=current_account)
    group = @group if !group
    unless account and group and (group.memberships.find_by(account: account) or account.admin?)
      flash[:notice] = 'You must be a member of that group to access that page'
      session[:return_to] = request.url
      request.xhr? ? halt(403) : redirect(account ? '/' : '/accounts/sign_in')
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