
# SLAs project configuration ( activation of SLAs by trackers : sla_project_trackers )
resources :projects do
  resources :sla_project_trackers, path: "/settings/slas", :only => [:new, :create, :update, :edit, :destroy]
end

# Configuration globales : noms des SLA
resources :slas, path: "sla/slas" do
  collection do
    get 'context_menu'
  end  
end
# context_menu : bulk_destroy
match 'sla/slas', :controller => 'slas', :action => 'destroy', :via => :delete

resources :sla_types, path: "sla/types" do
  collection do
    get 'context_menu'
  end
end
# context_menu : bulk_destroy
match 'sla/types', :controller => 'sla_types', :action => 'destroy', :via => :delete

resources :sla_statuses, path: "sla/statuses" do
  collection do
    get 'context_menu'
  end
end
# context_menu : bulk_destroy
match 'sla/statuses', :controller => 'sla_statuses', :action => 'destroy', :via => :delete

resources :sla_holidays, path: "sla/holidays" do
  collection do
    get 'context_menu'
  end
end
# context_menu : bulk_destroy
match 'sla/holidays', :controller => 'sla_holidays', :action => 'destroy', :via => :delete

resources :sla_calendars, path: "sla/calendars" do
  collection do
    get 'context_menu'
  end
  resources :sla_schedules, path: "sla/schedules", shallow: true
end
# context_menu : bulk_destroy
match 'sla/calendars', :controller => 'sla_calendars', :action => 'destroy', :via => :delete

resources :sla_levels, path: "sla/levels" do
  collection do
    get 'context_menu'
  end  
end
# context_menu : bulk_destroy
match 'sla/levels', :controller => 'sla_levels', :action => 'destroy', :via => :delete

resources :sla_level_terms, path: "sla/level_terms" do
  collection do
    get 'context_menu'
  end  
end  
# context_menu : bulk_destroy
match 'sla/level_terms', :controller => 'sla_level_terms', :action => 'destroy', :via => :delete

resources :sla_calendar_holidays, path: "sla/calendar_holidays" do
  collection do
    get 'context_menu'
  end
end
# context_menu : bulk_destroy
match 'sla/calendar_holidays', :controller => 'sla_calendar_holidays', :action => 'destroy', :via => :delete
