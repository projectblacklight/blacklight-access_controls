# frozen_string_literal: true
describe Blacklight::AccessControls::Enforcement do
  let(:controller) { CatalogController.new }
  let(:search_builder) { SearchBuilder.new(method_chain, controller) }
  let(:method_chain) { SearchBuilder.default_processor_chain }
  let(:user) { User.new }
  let(:ability) { Ability.new(user) }

  subject { search_builder }

  before do
    allow(controller).to receive(:current_ability).and_return(ability)
  end

  describe '#apply_gated_discovery' do
    let(:fq_first) do
      solr_parameters = {}
      subject.send(:apply_gated_discovery, solr_parameters)
      solr_parameters[:fq].first
    end

    context 'Given I am not logged in' do
      it "Then I should be treated as a member of the 'public' group" do
        expect(fq_first).to eq '({!terms f=discover_access_group_ssim}public) OR ({!terms f=read_access_group_ssim}public)'
      end
      it "Then I should not be treated as a member of the 'registered' group" do
        expect(fq_first).to_not match(/registered/)
      end
    end

    context 'Given I am a registered user' do
      let(:groups) { %w(faculty africana-faculty) }
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
        expect(fq_first).to match(%r{\{!terms f=discover_access_group_ssim\}public,faculty,africana-faculty,registered})
        expect(fq_first).to match(%r{\{!terms f=read_access_group_ssim\}public,faculty,africana-faculty,registered})
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
          expect(fq_first).to match(%r{\{!terms f=discover_access_group_ssim\}public,abc:123,cde:567,registered})
          expect(fq_first).to match(%r{\{!terms f=read_access_group_ssim\}public,abc:123,cde:567,registered})
        end
      end
    end
  end

  describe '#except' do
    let(:user) { build(:user) }
    subject { search_builder.except('foo') }

    it 'keeps the current_ability set' do
      expect(subject.current_ability).to eq ability
    end
  end

  describe '#append' do
    let(:user) { build(:user) }
    subject { search_builder.append('foo') }

    it 'keeps the current_ability set' do
      expect(subject.current_ability).to eq ability
    end
  end

  describe '#apply_user_permissions' do
    describe 'when the user is a guest user (user key nil)' do
      it 'does not create filters' do
        expect(subject.send(:apply_user_permissions, %w(discover read))).to eq []
      end
    end

    describe 'when the user is a guest user (user key empty string)' do
      let(:user) { User.new(email: '') }
      it 'does not create filters' do
        expect(subject.send(:apply_user_permissions, %w(discover read))).to eq []
      end
    end
  end
end
