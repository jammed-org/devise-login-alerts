module DeviseLoginAlerts
  class Mailer < DeviseLoginAlerts.config.parent_mailer.constantize
    def new_device_login
      @login_attempt = params[:login_attempt]
      @user = @login_attempt.user
      @app_name = DeviseLoginAlerts.config.resolved_app_name
      @security_url = security_url

      mail(
        **sender,
        to: @user.email,
        subject: t('devise_login_alerts.mailer.new_device_login.subject', app_name: @app_name),
        template_path: 'devise_login_alerts/mailer'
      )
    end

    private

    def sender
      sender = DeviseLoginAlerts.config.mailer_sender
      sender ||= Devise.mailer_sender if self.class.default[:from].blank?
      sender = sender.call if sender.respond_to?(:call)
      sender ? { from: sender } : {}
    end

    def security_url
      custom = DeviseLoginAlerts.config.security_url
      return custom.call(@user, @login_attempt) if custom

      route = "new_#{@login_attempt.scope}_password_url"
      public_send(route) if respond_to?(route)
    end
  end
end
