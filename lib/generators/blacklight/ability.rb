# frozen_string_literal: true
class Ability
  include CanCan::Ability
  include Blacklight::AccessControls::Ability
end
