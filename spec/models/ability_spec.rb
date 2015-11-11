require 'spec_helper'
require 'cancan/matchers'

describe Ability do
  let(:ability) { Ability.new(user) }

  let(:public_record) { SolrDocument.new(id: 'pub_rec') }
  let(:private_record) { SolrDocument.new(id: 'pri_rec') }

  context 'not logged in' do
    subject { ability }
    let(:user) { nil }

    it {
      is_expected.to     be_able_to(:discover, public_record)
      is_expected.to     be_able_to(:read, public_record)
      is_expected.to_not be_able_to(:discover, private_record)
#      is_expected.to_not be_able_to(:read, private_record)
    }
  end


  describe '.user_class' do
    subject { Blacklight::AccessControls::Ability.user_class }
    it { is_expected.to eq User }
  end

  describe '#guest_user' do
    let(:user) { nil }
    subject { ability.guest_user }

    it 'is a new user' do
      expect(subject).to be_a User
      expect(subject.new_record?).to be_truthy
    end
  end

  describe '#user_groups' do
    subject { ability.user_groups }

    context 'an unregistered user' do
      let(:user) { build(:user) }
      it { is_expected.to contain_exactly('public') }
    end

    context 'a registered user' do
      let(:user) { create(:user) }
      it { is_expected.to contain_exactly('registered', 'public') }
    end

    context 'a user with groups' do
      let(:user) { double(groups: ['group1', 'group2'], new_record?: false) }
      it { is_expected.to include('group1', 'group2') }
    end
  end

end
