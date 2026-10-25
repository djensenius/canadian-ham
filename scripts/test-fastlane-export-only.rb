#!/usr/bin/env ruby
require "minitest/autorun"

# Evaluate the real Fastfile with only its lane-registration DSL stubbed. No
# signing, API calls or uploads run; the upload_beta entry point is exercised.
module FastlaneCore
  module Helper; end
end

class BetaLaneHarness
  module UI
    def self.success(_message); end
    def self.user_error!(message) = raise(message)
  end

  def self.opt_out_usage; end
  def self.default_platform(_platform); end
  def self.desc(_description); end
  def self.lane(_name); end
  def self.before_all; end
  def self.platform(_name, &block) = block.call

  fastfile = File.expand_path("../fastlane/Fastfile", __dir__)
  class_eval(File.read(fastfile), fastfile)

  attr_reader :archives, :uploads

  def initialize
    @archives = []
    @uploads = []
  end

  def archive_and_export(platform_key, official_reference_sheet:)
    @archives << [platform_key, official_reference_sheet]
    config = self.class::BETA_PLATFORMS.fetch(platform_key)
    { artifact: config[:artifact], artifact_path: "/export/CanadianHam.#{config[:artifact]}", app_platform: config[:app_platform] }
  end

  def upload_to_testflight(**args)
    @uploads << args
  end
end

class FastlaneExportOnlyTests < Minitest::Test
  def test_export_only_archives_but_never_uploads_for_ios_and_mac
    [:ios, :mac].each do |platform|
      [true, "true"].each do |option|
        lane = BetaLaneHarness.new
        result = lane.upload_beta(platform, export_only: option)
        assert_equal [[platform, true]], lane.archives
        assert_empty lane.uploads
        assert_equal "/export/CanadianHam.#{platform == :ios ? 'ipa' : 'pkg'}", result[:artifact_path]
      end
    end
  end

  def test_default_and_false_keep_internal_upload_behaviour
    [{}, { export_only: false }, { export_only: "false" }].each do |options|
      lane = BetaLaneHarness.new
      lane.upload_beta(:ios, options)
      assert_equal [[:ios, true]], lane.archives
      assert_equal [{ app_identifier: "org.davidjensenius.CanadianHam", app_platform: "ios", skip_waiting_for_build_processing: true, ipa: "/export/CanadianHam.ipa" }], lane.uploads
    end
  end

  def test_existing_artifact_can_be_inspected_without_upload
    lane = BetaLaneHarness.new
    result = lane.upload_beta(:ios, artifact_path: __FILE__, export_only: "true")
    assert_empty lane.archives
    assert_empty lane.uploads
    assert_equal File.expand_path(__FILE__), result[:artifact_path]
  end
end
