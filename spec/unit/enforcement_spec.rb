# frozen_string_literal: true
require 'spec_helper'

describe Blacklight::AccessControls::Enforcement do
  let(:controller) { CatalogController.new }
  let(:search_builder) { SearchBuilder.new(method_chain, context) }
  let(:method_chain) { SearchBuilder.default_processor_chain }
  let(:context) { controller }

  let(:user) { User.new }
  let(:ability) { Ability.new(user) }

  subject { search_builder }

  describe "When I am searching for content" do
    before do
      @solr_parameters = {}
    end

    context "Given I am not logged in" do
      before do
        subject.current_ability = ability
        subject.send(:apply_gated_discovery, @solr_parameters)
      end

      it "Then I should be treated as a member of the 'public' group" do
        expect(@solr_parameters[:fq].first).to eq 'discover_access_group_ssim:public OR read_access_group_ssim:public'
      end

      it "Then I should not be treated as a member of the 'registered' group" do
        expect(@solr_parameters[:fq].first).to_not match(/registered/)
      end
    end

    context "Given I am a registered user" do
      let(:user) { create(:user) }

      before do
        allow(user).to receive(:groups) { ["faculty", "africana-faculty"] }
        subject.current_ability = Ability.new(user)
        subject.send(:apply_gated_discovery, @solr_parameters)
      end

      it "Then I should be treated as a member of the 'public' and 'registered' groups" do
        ["discover","read"].each do |type|
          expect(@solr_parameters[:fq].first).to match(/#{type}_access_group_ssim\:public/)
          expect(@solr_parameters[:fq].first).to match(/#{type}_access_group_ssim\:registered/)
        end
      end

      it "Then I should see assets that I have discover or read access to" do
        ["discover","read"].each do |type|
          expect(@solr_parameters[:fq].first).to match(/#{type}_access_person_ssim\:#{user.user_key}/)
        end
      end

      it "Then I should see assets that my groups have discover or read access to" do
        ["faculty", "africana-faculty"].each do |group_id|
          ["discover","read"].each do |type|
            expect(@solr_parameters[:fq].first).to match(/#{type}_access_group_ssim\:#{group_id}/)
          end
        end
      end
    end
  end

  describe "#except" do
    let(:user) { build(:user) }
    let(:ability) { Ability.new(user) }
    before { search_builder.current_ability = ability }
    subject { search_builder.except('foo') }

    it "keeps the current_ability set" do
      expect(subject.current_ability).to eq ability
    end
  end

  describe "#append" do
    let(:user) { build(:user) }
    let(:ability) { Ability.new(user) }
    before { search_builder.current_ability = ability }
    subject { search_builder.append('foo') }

    it "keeps the current_ability set" do
      expect(subject.current_ability).to eq ability
    end
  end

  describe "apply_gated_discovery" do
    let(:user) { create(:user) }
    let(:groups) { ["archivist","researcher"] }

    before do
      allow(user).to receive(:groups) { groups }
      subject.current_ability = Ability.new(user)
      @solr_parameters = {}
    end

    it "should set query fields for the user id checking against the discover, read fields" do
      subject.send(:apply_gated_discovery, @solr_parameters)
      ["discover","read"].each do |type|
        expect(@solr_parameters[:fq].first).to match(/#{type}_access_person_ssim\:#{user.user_key}/)
      end
    end

    it "should set query fields for all roles the user is a member of checking against the discover, read fields" do
      subject.send(:apply_gated_discovery, @solr_parameters)
      ["discover","read"].each do |type|
        expect(@solr_parameters[:fq].first).to match(/#{type}_access_group_ssim\:archivist/)
        expect(@solr_parameters[:fq].first).to match(/#{type}_access_group_ssim\:researcher/)
      end
    end

    context 'slashes in the group names' do
      let(:groups) { ["abc/123","cde/567"] }

      it "should escape slashes" do
        subject.send(:apply_gated_discovery, @solr_parameters)
        ["discover","read"].each do |type|
          expect(@solr_parameters[:fq].first).to match(/#{type}_access_group_ssim\:abc\\\/123/)
            expect(@solr_parameters[:fq].first).to match(/#{type}_access_group_ssim\:cde\\\/567/)
        end
      end
    end

    context 'spaces in the group names' do
      let(:groups) { ["abc 123","cd/e 567"] }

      it "should escape spaces" do
        subject.send(:apply_gated_discovery, @solr_parameters)
        ["discover","read"].each do |type|
          expect(@solr_parameters[:fq].first).to match(/#{type}_access_group_ssim\:abc\\ 123/)
            expect(@solr_parameters[:fq].first).to match(/#{type}_access_group_ssim\:cd\\\/e\\ 567/)
        end
      end
    end

    context 'colons in the groups names' do
      let(:groups) { ["abc:123","cde:567"] }

      it "should escape colons" do
        subject.send(:apply_gated_discovery, @solr_parameters)
        ["discover","read"].each do |type|
          expect(@solr_parameters[:fq].first).to match(/#{type}_access_group_ssim\:abc\\:123/)
            expect(@solr_parameters[:fq].first).to match(/#{type}_access_group_ssim\:cde\\:567/)
        end
      end
    end
  end

  describe "apply_user_permissions" do
    describe "when the user is a guest user (user key nil)" do
      before { subject.current_ability = ability }

      it "should not create filters" do
        expect(subject.send(:apply_user_permissions, ["discover","read"])).to eq []
      end
    end

    describe "when the user is a guest user (user key empty string)" do
      let(:user) { User.new(email: '') }
      before { subject.current_ability = ability }

      it "should not create filters" do
        expect(subject.send(:apply_user_permissions, ["discover","read"])).to eq []
      end
    end
  end

end
