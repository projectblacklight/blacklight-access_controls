require 'spec_helper'

describe Blacklight::AccessControls::Config do
  let(:config) { described_class.new }

  describe '#user_model' do
    it 'has a default value' do
      expect(config.user_model).to eq 'User'
    end

    it 'can be set to a non-default value' do
      config.user_model = 'Student'
      expect(config.user_model).to eq 'Student'
    end
  end
end
