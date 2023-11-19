  # frozen_string_literal: true

module ObjectHelpers

  # Generates an unsaved Sla
  def Sla.generate(attributes={})
    sla = Sla.new()
    sla.name = 'Generated SLA' if sla.name.blank?
    yield sla if block_given?
    sla
  end

  # Generates a saved Sla
  def Sla.generate!(attributes={}, &block)
    sla = Sla.generate(attributes, &block)
    sla.save!
    sla.reload
  end

  # Generates an unsaved SlaType
  def SlaType.generate(attributes={})
    sla_type = SlaType.new()
    sla_type.name = 'Generated SLA Type' if sla_type.name.blank?
    yield sla_type if block_given?
    sla_type
  end

  # Generates a saved SlaType
  def SlaType.generate!(attributes={}, &block)
    sla_type = SlaType.generate(attributes, &block)
    sla_type.save!
    sla_type.reload
  end

  # Generates an unsaved SlaCalendar
  def SlaCalendar.generate(attributes={})
    sla_calendar = SlaCalendar.new()
    sla_calendar.name = 'Generated SLA Calendar' if sla_calendar.name.blank?
    yield sla_calendar if block_given?
    sla_calendar
  end

  # Generates a saved SlaCalendar
  def SlaCalendar.generate!(attributes={}, &block)
    sla_calendar = SlaCalendar.generate(attributes, &block)
    sla_calendar.save!
    sla_calendar.reload
  end

end
