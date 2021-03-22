Rails.application.routes.draw do
  root to: 'home#index'

  get '/managers', to: 'managers#index', as: :managers
  get '/newest', to: 'thirteen_fs#newest_filings', as: :newest_filings

  get '/manager/:id', to: 'thirteen_fs#manager', as: :manager
  get '/manager/:cik/cusip/:cusip', to: 'thirteen_fs#manager_cusip_history', as: :manager_cusip_history

  get '/13f/:id', to: 'thirteen_fs#holdings_aggregated', as: :thirteen_f
  get '/13f/:id/detailed', to: 'thirteen_fs#holdings_detailed', as: :thirteen_f_detailed
  get '/13f/:external_id/compare/:other_external_id', to: 'thirteen_fs#compare_holdings', as: :thirteen_f_comparison

  get '/cusip/:cusip/:year/:quarter', to: 'thirteen_fs#all_cusip_holders', as: :all_cusip_holders
  get '/cusip/:cusip', to: 'thirteen_fs#cusip_index', as: :cusip_index

  get '/data/autocomplete', to: 'data#autocomplete', as: :autocomplete
  get '/data/13f/:external_id', to: 'data#thirteen_f_data', as: :thirteen_f_data
  get '/data/13f/:external_id/detailed', to: 'data#thirteen_f_detailed_data', as: :thirteen_f_detailed_data
  get '/data/13f/:external_id/compare/:other_external_id', to: 'data#compare_holdings_data', as: :thirteen_f_comparison_data
  get '/data/cusip/:cusip/:year/:quarter', to: 'data#all_cusip_holders_data', as: :all_cusip_holders_data
  get '/data/manager/:cik/cusip/:cusip', to: 'data#manager_cusip_history_data', as: :manager_cusip_history_data
end
