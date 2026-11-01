module DeviseLoginAlerts
  Event = Data.define(:name, :login_attempt, :first_device) do
    delegate :user, :successful?, :failure_reason, :new_device?, :alerted?, to: :login_attempt

    def device
      return :known unless new_device?

      first_device ? :first : :new
    end
  end
end
