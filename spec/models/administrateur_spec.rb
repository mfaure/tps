require 'spec_helper'

describe Administrateur, type: :model do
  let(:administration) { create(:administration) }

  describe 'assocations' do
    it { is_expected.to have_and_belong_to_many(:gestionnaires) }
    it { is_expected.to have_many(:procedures) }
  end

  context 'unified login' do
    it 'syncs credentials to associated user' do
      administrateur = create(:administrateur)
      user = create(:user, email: administrateur.email)

      administrateur.update(email: 'whoami@plop.com', password: 'super secret')

      user.reload
      expect(user.email).to eq('whoami@plop.com')
      expect(user.valid_password?('super secret')).to be(true)
    end

    it 'syncs credentials to associated administrateur' do
      administrateur = create(:administrateur)
      gestionnaire = create(:gestionnaire, email: administrateur.email)

      administrateur.update(email: 'whoami@plop.com', password: 'super secret')

      gestionnaire.reload
      expect(gestionnaire.email).to eq('whoami@plop.com')
      expect(gestionnaire.valid_password?('super secret')).to be(true)
    end
  end

  describe "#renew_api_token" do
    let(:administrateur) { create(:administrateur) }

    before do
      administrateur.renew_api_token
      administrateur.reload
    end

    it { expect(administrateur.api_token).to be_present }
    it { expect(administrateur.api_token).not_to eq(administrateur.encrypted_token) }
    it { expect(BCrypt::Password.new(administrateur.encrypted_token)).to eq(administrateur.api_token) }

    context 'when it s called twice' do
      let!(:previous_token) { administrateur.api_token }

      it { expect(previous_token).not_to eq(administrateur.renew_api_token) }
    end
  end

  describe '#find_inactive_by_token' do
    let(:administrateur) { create(:administration).invite_admin('paul@tps.fr') }
    let(:reset_password_token) { administrateur.invite!(administration.id) }

    it { expect(Administrateur.find_inactive_by_token(reset_password_token)).not_to be_nil }
  end

  describe '#reset_password' do
    let(:administrateur) { create(:administration).invite_admin('paul@tps.fr') }
    let(:reset_password_token) { administrateur.invite!(administration.id) }

    it { expect(Administrateur.reset_password(reset_password_token, '12345678').errors).to be_empty }
    it { expect(Administrateur.reset_password('123', '12345678').errors).not_to be_empty }
    it { expect(Administrateur.reset_password(reset_password_token, '').errors).not_to be_empty }
  end

  describe '#feature_enabled?' do
    let(:administrateur) { create(:administrateur) }

    before do
      administrateur.enable_feature(:champ_pj)
    end

    it { expect(administrateur.feature_enabled?(:champ_siret)).to be_falsey }
    it { expect(administrateur.feature_enabled?(:champ_pj)).to be_truthy }
  end
end
