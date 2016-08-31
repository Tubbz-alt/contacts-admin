require 'rails_helper'
require 'redirector_for_gone_contact'
require 'gds_api/test_helpers/content_store'
require 'gds_api/test_helpers/publishing_api'

describe RedirectorForGoneContact do
  let(:organisation) { create :organisation, title: 'Ministry of Hats' }
  let(:organisation_slug) { organisation.slug }
  let(:redirect_to_location) { '/find-my-nearest/hat-shop' }

  subject(:redirector) do
    RedirectorForGoneContact.new(
      contact_slug: contact_slug,
      organisation_slug: organisation_slug,
      redirect_to_location: redirect_to_location
    )
  end

  context 'when the contact_slug refers to a contact in the db' do
    let!(:contact) { create :contact, title: 'Chief Milliners Office', organisation: organisation }
    let(:contact_slug) { contact.slug }

    it 'is not successful when doing the redirect' do
      expect(subject.redirect_gone_contact).not_to be_successful
    end

    it 'provides a reason for the failure' do
      expect(subject.redirect_gone_contact.reason).to eq(:contact_exists)
    end

    it 'does not publish a redirect' do
      expect(Publisher).to_not receive(:publish)
      subject.redirect_gone_contact
    end
  end

  context 'when the contact_slug does not refer to a contact in the db' do
    include GdsApi::TestHelpers::ContentStore

    let(:contact_slug) { 'chief-milliners-office' }
    let(:path_in_content_store) { "/government/organisations/#{organisation_slug}/contact/#{contact_slug}" }

    context 'and does not refer to something in the content-store' do
      before { content_store_does_not_have_item path_in_content_store }

      it 'is not successful when doing the redirect' do
        expect(subject.redirect_gone_contact).not_to be_successful
      end

      it 'provides a reason for the failure' do
        expect(subject.redirect_gone_contact.reason).to eq(:unpublished_contact)
      end

      it 'does not publish a redirect' do
        expect(Publisher).to_not receive(:publish)
        subject.redirect_gone_contact
      end
    end

    context 'and refers to an non-"gone" object in the content-store' do
      before { content_store_has_item path_in_content_store }

      it 'is not successful when doing the redirect' do
        expect(subject.redirect_gone_contact).not_to be_successful
      end

      it 'provides a reason for the failure' do
        expect(subject.redirect_gone_contact.reason).to eq(:not_gone)
      end

      it 'does not publish a redirect' do
        expect(Publisher).to_not receive(:publish)
        subject.redirect_gone_contact
      end
    end

    context 'and refers to a "gone" object in the content-store' do
      include GdsApi::TestHelpers::PublishingApiV2

      let(:gone_item) do
        content_item_for_base_path(path_in_content_store).
          merge(
            "format" => "gone",
          )
      end

      before { content_store_has_item path_in_content_store, gone_item }

      it 'sends a redirect to the publishing-api for the contact' do
        subject.redirect_gone_contact

        assert_publishing_api_put_content(
          subject.redirect_content_item_content_id,
          request_json_includes(
            redirects: [
              {
                path: path_in_content_store,
                type: "exact",
                destination: redirect_to_location,
              }
            ]
          )
        )
      end

      context 'and communicating with the publishing-api is succesful' do
        before { stub_any_publishing_api_put_content }

        it 'is successful when doing the redirect' do
          expect(subject.redirect_gone_contact).to be_successful
        end
      end

      context 'and communicating with the publishing-api fails' do
        before { stub_any_publishing_api_put_content.to_return(status: 422, body: "Uh oh!") }

        it 'is unsuccessful when doing the redirect' do
          expect(subject.redirect_gone_contact).not_to be_successful
        end

        it 'provides a reason for the failure' do
          expect(subject.redirect_gone_contact.reason).to eq(:redirect_failed)
        end

        it 'includes the error message' do
          expect(subject.redirect_gone_contact.message).to eq("PublishingApi Error: Redirect failed")
        end
      end
    end
  end
end
