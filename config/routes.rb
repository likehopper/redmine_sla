
# File: redmine_sla/config/routes.rb

# SLAs project configuration ( activation of SLAs by trackers : sla_project_trackers )
resources :projects do
  resources :sla_caches, path: "sla/caches", :only => [ :index, :show, :destroy ] do
    member do
      get 'refresh'
    end
    collection do
      get 'context_menu', 'purge'
    end    
  end
  resources :sla_project_trackers, path: "sla/trackers", :only => [ :index, :new, :create, :update, :edit, :destroy]
  # resources :sla_project_trackers, path: "/settings/slas/(.:format)", :only => [ :index ]
end
resources :sla_project_trackers, path: "sla/project_trackers", :only => [ :index, :new, :create, :update, :edit, :destroy] do
  collection do
    get 'context_menu'
  end  
end
# context_menu : bulk_destroy
match 'sla/project_trackers', :controller => 'sla_project_trackers', :action => 'destroy', :via => :delete

# SLA Global settings - Slas
resources :slas, path: "sla/slas" do
  collection do
    get 'context_menu'
  end  
end
# context_menu : bulk_destroy
match 'sla/slas', :controller => 'slas', :action => 'destroy', :via => :delete

# SLA Global settings - Sla Types
resources :sla_types, path: "sla/types" do
  collection do
    get 'context_menu'
  end
end
# context_menu : bulk_destroy
match 'sla/types', :controller => 'sla_types', :action => 'destroy', :via => :delete

# SLA Global settings - Sla Statuses
resources :sla_statuses, path: "sla/statuses" do
  collection do
    get 'context_menu'
  end
end
# context_menu : bulk_destroy
match 'sla/statuses', :controller => 'sla_statuses', :action => 'destroy', :via => :delete

# SLA Global settings - Sla Holidays
resources :sla_holidays, path: "sla/holidays" do
  collection do
    get 'context_menu'
  end
end
# context_menu : bulk_destroy
match 'sla/holidays', :controller => 'sla_holidays', :action => 'destroy', :via => :delete

# SLA Global settings - Sla Calendars
resources :sla_calendars, path: "sla/calendars" do
  collection do
    get 'context_menu'
  end
  resources :sla_schedules, path: "sla/schedules", shallow: true
end
# context_menu : bulk_destroy
match 'sla/calendars', :controller => 'sla_calendars', :action => 'destroy', :via => :delete

# SLA Global settings - Sla Schedules
resources :sla_schedules, path: "sla/schedules" do
  collection do
    get 'context_menu'
  end
end
# context_menu : bulk_destroy
match 'sla/schedules', :controller => 'sla_schedules', :action => 'destroy', :via => :delete

# SLA Global settings - Sla Levels
resources :sla_levels, path: "sla/levels" do
  member do
    get 'sla_terms'
  end
  collection do
    get 'context_menu'
  end
end
# context_menu : bulk_destroy
match 'sla/levels', :controller => 'sla_levels', :action => 'destroy', :via => :delete

# SLA Global settings - Sla Level Terms
resources :sla_level_terms, path: "sla/level_terms", only: [:index, :show, :destroy] do # except: [:new, :create, :edit, :update] do
  collection do
    get 'context_menu'
  end  
end  
# context_menu : bulk_destroy
match 'sla/level_terms', :controller => 'sla_level_terms', :action => 'destroy', :via => :delete

# SLA Global settings - Sla Calendar Holidays
resources :sla_calendar_holidays, path: "sla/calendar_holidays" do
  collection do
    get 'context_menu'
  end
end
# context_menu : bulk_destroy
match 'sla/calendar_holidays', :controller => 'sla_calendar_holidays', :action => 'destroy', :via => :delete

# SLA Global settings - Sla Caches
resources :sla_caches, path: "sla/caches", except: [:new, :create, :edit, :update] do
  member do
    get 'refresh'
  end
  collection do
    get 'context_menu', 'refresh', 'purge'
  end
end
# context_menu : bulk_destroy
match 'sla/caches', :controller => 'sla_caches', :action => 'destroy', :via => :delete

# SLA Global settings - Sla Cache Spents
resources :sla_cache_spents, path: "sla/cache_spents", except: [:new, :create, :edit, :update] do
  member do
    get 'refresh'
  end
  collection do
    get 'context_menu', 'refresh', 'purge'
  end
end
# context_menu : bulk_destroy
match 'sla/cache_spents', :controller => 'sla_cache_spents', :action => 'destroy', :via => :delete