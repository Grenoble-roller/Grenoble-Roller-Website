# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#human_status' do
    context 'with order scope' do
      it 'returns French label for pending' do
        expect(helper.human_status(:order, 'pending')).to eq('En attente')
      end

      it 'returns French label for paid' do
        expect(helper.human_status(:order, 'paid')).to eq('Payée')
      end

      it 'returns French label for shipped' do
        expect(helper.human_status(:order, 'shipped')).to eq('Expédiée')
      end

      it 'returns French label for cancelled' do
        expect(helper.human_status(:order, 'cancelled')).to eq('Annulée')
      end
    end

    context 'with membership scope' do
      it 'returns French label for pending' do
        expect(helper.human_status(:membership, 'pending')).to eq('En attente')
      end

      it 'returns French label for active' do
        expect(helper.human_status(:membership, 'active')).to eq('Active')
      end

      it 'returns French label for trial' do
        expect(helper.human_status(:membership, 'trial')).to eq('Essai gratuit')
      end
    end

    context 'with attendance scope' do
      it 'returns French label for paid' do
        expect(helper.human_status(:attendance, 'paid')).to eq('Payé')
      end

      it 'returns French label for present' do
        expect(helper.human_status(:attendance, 'present')).to eq('Présent')
      end
    end

    context 'with event scope' do
      it 'returns French label for draft' do
        expect(helper.human_status(:event, 'draft')).to eq('En attente de validation')
      end

      it 'returns French label for published' do
        expect(helper.human_status(:event, 'published')).to eq('Publié')
      end

      it 'returns French label for rejected' do
        expect(helper.human_status(:event, 'rejected')).to eq('Refusé')
      end

      it 'returns French label for canceled' do
        expect(helper.human_status(:event, 'canceled')).to eq('Annulé')
      end
    end

    context 'when value is blank' do
      it 'returns empty string' do
        expect(helper.human_status(:order, nil)).to eq('')
        expect(helper.human_status(:order, '')).to eq('')
      end
    end

    context 'when translation is missing' do
      it 'falls back to humanized value' do
        result = helper.human_status(:order, 'unknown_status')
        expect(result).to be_present
        expect(result).to eq('Unknown status') # humanize default
      end
    end
  end
end
