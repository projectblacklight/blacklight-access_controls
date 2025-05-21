# frozen_string_literal: true

RSpec.describe Blacklight::AccessControls::SearchBuilder do
  subject(:search_builder) { described_class.new scope, ability: ability }

  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:scope) { double blacklight_config: blacklight_config, search_state_class: nil }
  let(:user) { User.new }
  let(:ability) { Ability.new(user) }

  before { allow(controller).to receive(:blacklight_config) }

  describe '#discovery_permissions' do
    subject { search_builder.default_permission_types }

    it { is_expected.to eq %w[discover read] }
  end

  describe '#apply_gated_discovery' do
    let(:fq_first) do
      solr_parameters = {}
      search_builder.send(:apply_gated_discovery, solr_parameters)
      solr_parameters[:fq].first
    end

    describe 'logger' do
      # Expectation will be triggered by Ability class (that calls Rails.logger.debug earlier). So we double Ability to avoid false positive.
      let(:ability) { instance_double(Ability, user_groups: [], current_user: user) }

      it 'is called with debug' do
        allow(Rails.logger).to receive(:debug)
        search_builder.send(:apply_gated_discovery, {})
        expect(Rails.logger).to have_received(:debug).with(/^Solr parameters/)
      end
    end

    context 'Given I am not logged in' do
      it "Then I should be treated as a member of the 'public' group" do
        expect(fq_first).to eq '({!terms f=discover_access_group_ssim}public) OR ({!terms f=read_access_group_ssim}public)'
      end

      it "Then I should not be treated as a member of the 'registered' group" do
        expect(fq_first).not_to match(/registered/)
      end
    end

    context 'Given I am a registered user' do
      let(:groups) { %w[faculty africana-faculty] }
      let(:user) do
        create(:user).tap do |u|
          allow(u).to receive(:groups) { groups }
        end
      end

      it 'searches for my user key in discover and read fields' do
        expect(fq_first).to match(/discover_access_person_ssim\:#{user.user_key}/)
        expect(fq_first).to match(/read_access_person_ssim\:#{user.user_key}/)
      end

      it 'searches for my groups' do
        expect(fq_first).to match(/\{!terms f=discover_access_group_ssim\}public,faculty,africana-faculty,registered/)
        expect(fq_first).to match(/\{!terms f=read_access_group_ssim\}public,faculty,africana-faculty,registered/)
      end

      it 'does not build empty clauses' do
        expect(search_builder).to receive(:apply_user_permissions).and_return(['({!terms f=discover_access_group_ssim}public,faculty,africana-faculty,registered)', '', nil])
        expect(fq_first).not_to match(/ OR $/) # i.e. doesn't end w/ empty
      end

      context 'slashes in the group names' do
        let(:groups) { ['abc/123', 'cde/567'] }

        it 'does not escape slashes' do
          expect(fq_first).to match(%r{\{!terms f=discover_access_group_ssim\}public,abc/123,cde/567,registered})
          expect(fq_first).to match(%r{\{!terms f=read_access_group_ssim\}public,abc/123,cde/567,registered})
        end
      end

      context 'spaces in the group names' do
        let(:groups) { ['abc 123', 'cd/e 567'] }

        it 'does not escape spaces in group names' do
          expect(fq_first).to match(%r{\{!terms f=discover_access_group_ssim\}public,abc 123,cd/e 567,registered})
          expect(fq_first).to match(%r{\{!terms f=read_access_group_ssim\}public,abc 123,cd/e 567,registered})
        end
      end

      context 'colons in the groups names' do
        let(:groups) { ['abc:123', 'cde:567'] }

        it 'does not escape colons' do
          expect(fq_first).to match(/\{!terms f=discover_access_group_ssim\}public,abc:123,cde:567,registered/)
          expect(fq_first).to match(/\{!terms f=read_access_group_ssim\}public,abc:123,cde:567,registered/)
        end
      end
    end
  end

  describe '#apply_user_permissions' do
    describe 'when the user is a guest user (user key nil)' do
      it 'does not create filters' do
        expect(search_builder.send(:apply_user_permissions)).to eq []
      end
    end

    describe 'when the user is a guest user (user key empty string)' do
      let(:user) { User.new(email: '') }

      it 'does not create filters' do
        expect(search_builder.send(:apply_user_permissions)).to eq []
      end
    end
  end
end
