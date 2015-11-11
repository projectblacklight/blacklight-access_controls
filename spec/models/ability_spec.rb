require 'spec_helper'
require 'cancan/matchers'

describe Ability do
  let(:ability) { Ability.new(user) }

  describe "Given an asset that has been made publicly discoverable" do
    let(:asset) { create_solr_doc(id: 'public_discovery',
                  discover_access_group_ssim: 'public') }

    context "Then a not-signed-in user" do
      let(:user) { nil }
      subject { ability }

      it { should     be_able_to(:discover, asset) }
      it { should_not be_able_to(:read, asset) }
    end

    context "Then a registered user" do
      let(:user) { create(:user) }
      subject { ability }

      it { should     be_able_to(:discover, asset) }
      it { should_not be_able_to(:read, asset) }
    end
  end

  describe "Given an asset that has been made publicly available (ie. open access)" do
    let(:asset) { create_solr_doc(id: 'public_read',
                  read_access_group_ssim: 'public') }

    context "Then a not-signed-in user" do
      let(:user) { nil }
      subject { ability }

      it { should be_able_to(:discover, asset) }
      it { should be_able_to(:read, asset) }
    end

    context "Then a registered user" do
      let(:user) { create(:user) }
      subject { ability }

      it { should be_able_to(:discover, asset) }
      it { should be_able_to(:read, asset) }
    end
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
