module Users
  class CommencerController < ApplicationController
    layout 'procedure_context'

    def commencer
      @procedure = retrieve_procedure
      return procedure_not_found if @procedure.blank? || @procedure.brouillon?

      render 'commencer/show'
    end

    def commencer_test
      @procedure = retrieve_procedure
      return procedure_not_found if @procedure.blank? || @procedure.publiee?

      render 'commencer/show'
    end

    def sign_in
      @procedure = retrieve_procedure
      return procedure_not_found if @procedure.blank?

      store_user_location!(@procedure)
      redirect_to new_user_session_path
    end

    def sign_up
      @procedure = retrieve_procedure
      return procedure_not_found if @procedure.blank?

      store_user_location!(@procedure)
      redirect_to new_user_registration_path
    end

    def france_connect
      @procedure = retrieve_procedure
      return procedure_not_found if @procedure.blank?

      store_user_location!(@procedure)
      redirect_to france_connect_particulier_path
    end

    def procedure_for_help
      retrieve_procedure
    end

    private

    def retrieve_procedure
      Procedure.publiees.or(Procedure.brouillons).find_by(path: params[:path])
    end

    def procedure_not_found
      procedure = Procedure.find_by(path: params[:path])

      if procedure&.archivee?
        flash.alert = t('errors.messages.procedure_archived')
      else
        flash.alert = t('errors.messages.procedure_not_found')
      end

      redirect_to root_path
    end

    def store_user_location!(procedure)
      store_location_for(:user, helpers.procedure_lien(procedure))
    end
  end
end
