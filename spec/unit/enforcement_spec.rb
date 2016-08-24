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

  before do
    allow(controller).to receive(:current_ability).and_return(ability)
  end

  describe "When I am searching for content" do
    before do
      @solr_parameters = {}
    end

    context "Given I am not logged in" do
      before do
        subject.send(:apply_gated_discovery, @solr_parameters)
      end

      it "Then I should be treated as a member of the 'public' group" do
        expect(@solr_parameters[:fq].first).to eq '({!terms f=discover_access_group_ssim}public) OR ({!terms f=read_access_group_ssim}public)'
      end

      it "Then I should not be treated as a member of the 'registered' group" do
        expect(@solr_parameters[:fq].first).to_not match(/registered/)
      end
    end

    context "Given I am a registered user" do
      let(:user) do
        create(:user).tap do |u|
          allow(u).to receive(:groups) { ["faculty", "africana-faculty"] }
        end
      end

      before do
        subject.send(:apply_gated_discovery, @solr_parameters)
      end

      it "searches for my groups" do
        expect(@solr_parameters[:fq].first).to match(%r{\{!terms f=discover_access_group_ssim\}public,faculty,africana-faculty,registered})
        expect(@solr_parameters[:fq].first).to match(%r{\{!terms f=read_access_group_ssim\}public,faculty,africana-faculty,registered})
      end

      it "searches for my user key" do
        %w(discover read).each do |type|
          expect(@solr_parameters[:fq].first).to match(/#{type}_access_person_ssim\:#{user.user_key}/)
        end
      end
    end
  end

  describe "#except" do
    let(:user) { build(:user) }
    let(:ability) { Ability.new(user) }
    subject { search_builder.except('foo') }

    it "keeps the current_ability set" do
      expect(subject.current_ability).to eq ability
    end
  end

  describe "#append" do
    let(:user) { build(:user) }
    let(:ability) { Ability.new(user) }
    subject { search_builder.append('foo') }

    it "keeps the current_ability set" do
      expect(subject.current_ability).to eq ability
    end
  end

  describe "apply_gated_discovery" do
    let(:user) do
      create(:user).tap do |u|
        allow(u).to receive(:groups) { groups }
      end
    end
    let(:groups) { %w(archivist researcher) }

    before do
      @solr_parameters = {}
      subject.send(:apply_gated_discovery, @solr_parameters)
    end

    it "sets query fields for the user id checking against the discover, read fields" do
      %w(discover read).each do |type|
        expect(@solr_parameters[:fq].first).to match(/#{type}_access_person_ssim\:#{user.user_key}/)
      end
    end

    it "queries roles the user is a member of checking against the discover, read fields" do
      expect(@solr_parameters[:fq].first).to match(%r{\{!terms f=discover_access_group_ssim\}public,archivist,researcher,registered})
      expect(@solr_parameters[:fq].first).to match(%r{\{!terms f=read_access_group_ssim\}public,archivist,researcher,registered})
    end

    context 'slashes in the group names' do
      let(:groups) { ["abc/123", "cde/567"] }

      it "doesn't escape slashes" do
        expect(@solr_parameters[:fq].first).to match(%r{\{!terms f=discover_access_group_ssim\}public,abc/123,cde/567,registered})
        expect(@solr_parameters[:fq].first).to match(%r{\{!terms f=read_access_group_ssim\}public,abc/123,cde/567,registered})
      end
    end

    context 'spaces in the group names' do
      let(:groups) { ["abc 123", "cd/e 567"] }

      it "doesn't escape spaces in group names" do
        expect(@solr_parameters[:fq].first).to match(%r{\{!terms f=discover_access_group_ssim\}public,abc 123,cd/e 567,registered})
        expect(@solr_parameters[:fq].first).to match(%r{\{!terms f=read_access_group_ssim\}public,abc 123,cd/e 567,registered})
      end
    end

    context 'colons in the groups names' do
      let(:groups) { ["abc:123", "cde:567"] }

      it "doesn't escape colons" do
        expect(@solr_parameters[:fq].first).to match(%r{\{!terms f=discover_access_group_ssim\}public,abc:123,cde:567,registered})
        expect(@solr_parameters[:fq].first).to match(%r{\{!terms f=read_access_group_ssim\}public,abc:123,cde:567,registered})
      end
    end
  end

  describe "apply_user_permissions" do
    describe "when the user is a guest user (user key nil)" do
      it "does not create filters" do
        expect(subject.send(:apply_user_permissions, %w(discover read))).to eq []
      end
    end

    describe "when the user is a guest user (user key empty string)" do
      let(:user) { User.new(email: '') }
      it "does not create filters" do
        expect(subject.send(:apply_user_permissions, %w(discover read))).to eq []
      end
    end
  end
end
