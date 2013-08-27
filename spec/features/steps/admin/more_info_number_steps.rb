require_relative 'more_info_record_steps'

module Admin
  module MoreInfoNumberSteps
    include ::CommonSteps
    include Admin::MoreInfoRecordSteps

    def new_more_info_record_link
      'a.new-more-info-number'
    end

    def create_more_info_number(contact_record, details = {})
      create_more_info_record(:more_info_number, contact_record, details)
    end

    def update_more_info_number(contact_record, new_details = {})
      update_more_info_record(:more_info_number, contact_record, new_details)
    end

    def more_info_number_updated(contact_record, details = {})
      more_info_record_updated(:more_info_number, contact_record, details)
    end
  end
end
