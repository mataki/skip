ActionMailer::Base.delivery_method = INITIAL_SETTINGS['delivery_method'].to_sym
ActionMailer::Base.raise_delivery_errors = INITIAL_SETTINGS['raise_delivery_errors']
