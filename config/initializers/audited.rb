# Configure YAML to permit additional classes for Audited
# This fixes the "Tried to dump unspecified class" error in Rails 8+
Rails.application.config.after_initialize do
  if defined?(Psych) && Psych.respond_to?(:add_permitted_class)
    [Date, Time, DateTime, Symbol, BigDecimal,
     ActiveSupport::HashWithIndifferentAccess,
     ActiveSupport::TimeWithZone,
     ActiveSupport::TimeZone].each do |klass|
      Psych.add_permitted_class(klass)
    end
  end
end
