require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

#Rails.backtrace_cleaner.remove_silencers!

class ActiveSupport::TestCase
  self.fixture_path = File.expand_path(File.dirname(__FILE__) + '/fixtures')
end

module ActionController::TestCase::Behavior
  def process_patched(action, method, *args)
    options = args.extract_options!
    if options.present?
      params = options.delete(:params)
      options = options.merge(params) if params.present?
      args << options
    end
    process_unpatched(action, method, *args)
  end
end
