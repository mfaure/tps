require 'spec_helper'

describe DossierFieldService do
  describe '#filtered_ids' do
    context 'for self table' do
      let(:procedure) { create(:procedure) }

      context 'for created_at column' do
        let!(:kept_dossier) { create(:dossier, procedure: procedure, created_at: DateTime.new(2018, 9, 18, 14, 28)) }
        let!(:discarded_dossier) { create(:dossier, procedure: procedure, created_at: DateTime.new(2018, 9, 17, 23, 59)) }

        subject { described_class.filtered_ids(procedure.dossiers, [{ 'table' => 'self', 'column' => 'created_at', 'value' => '18/9/2018' }]) }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'for updated_at column' do
        let!(:kept_dossier) { create(:dossier, procedure: procedure, updated_at: DateTime.new(2018, 9, 18, 14, 28)) }
        let!(:discarded_dossier) { create(:dossier, procedure: procedure, updated_at: DateTime.new(2018, 9, 17, 23, 59)) }

        subject { described_class.filtered_ids(procedure.dossiers, [{ 'table' => 'self', 'column' => 'updated_at', 'value' => '18/9/2018' }]) }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end
    end
  end
end
