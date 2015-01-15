class PermissionsController < ApplicationController
  before_action :session_required, only: :update
  before_action :find_model
  before_action :require_manage_authorization, only: :update
  before_action :show_permissions_alert, only: :show

  def update
    if find_model.update(model_params)
      flash.now[:success] = t('.success')
      render :show, status: :ok
    else
      flash.now[:error] = t('.error')
      render :show, status: :unprocessable_entity
    end
  end

  private

  def find_model
    @permission = current_project.permission || Permission.new(target: current_project)
    @permission.editor_account = current_user
    @permission
  end

  def model_params
    params.require(:permission).permit(:remainder)
  end

  def show_permissions_alert
    return if current_user_can_manage?
    flash.now[:notice] = logged_in? ? t('permissions.not_manager') : t('permissions.must_log_in')
  end

  def require_manage_authorization
    return if current_user_can_manage?
    flash.now[:error] = t(:not_authorized)
    render :show, status: :unauthorized
  end
end
