#!/usr/bin/env ruby
require "fileutils"
require "json"
require "minitest/autorun"
require "open3"

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

  attr_reader :archives, :uploads, :distributions

  def initialize
    @archives = []
    @uploads = []
    @distributions = []
  end

  def archive_and_export(platform_key, official_reference_sheet:, distribution: false)
    @archives << [platform_key, official_reference_sheet]
    @distributions << distribution
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

  def test_unrecognised_values_and_option_names_fail_before_archive_or_upload
    [{ export_only: "TRUE" }, { export_only: 1 }, { export_only: "yes" }].each do |options|
      lane = BetaLaneHarness.new
      lane.upload_beta(:ios, options)
      assert_empty lane.uploads, "#{options.inspect} must mean export only"
    end
    [{ export_only: "maybe" }, { export_only: "ture" }, { exportonly: true }, { export: "true" }].each do |options|
      lane = BetaLaneHarness.new
      assert_raises(RuntimeError) { lane.upload_beta(:ios, options) }
      assert_empty lane.archives, "#{options.inspect} must fail before archiving"
      assert_empty lane.uploads, "#{options.inspect} must never upload"
    end
  end

  def test_existing_artifact_can_be_inspected_without_upload
    lane = BetaLaneHarness.new
    result = lane.upload_beta(:ios, artifact_path: __FILE__, export_only: "true")
    assert_empty lane.archives
    assert_empty lane.uploads
    assert_equal File.expand_path(__FILE__), result[:artifact_path]
  end

  def test_default_and_false_distribution_keep_internal_export
    [{}, { distribution: false }, { distribution: "no" }].each do |options|
      lane = BetaLaneHarness.new
      lane.upload_beta(:ios, options.merge(export_only: true))
      assert_equal [[:ios, true]], lane.archives
      assert_equal [false], lane.distributions
      assert_empty lane.uploads
    end
    target = BetaLaneHarness.new.beta_export_target(false)
    assert_equal BetaLaneHarness::EXPORT_OPTIONS_PLIST, target[:export_options_plist]
    assert_equal BetaLaneHarness::BUILD_ROOT, target[:build_root]
    assert_equal BetaLaneHarness::ARCHIVE_ROOT, target[:archive_root]
  end

  def test_distribution_export_uses_app_store_options_without_official_sheet
    [:ios, :mac, :appletvos, :xros].each do |platform|
      [true, "true", "YES", "1"].each do |option|
        lane = BetaLaneHarness.new
        lane.upload_beta(platform, distribution: option, export_only: true)
        assert_equal [[platform, false]], lane.archives, "distribution must not opt in to the official sheet"
        assert_equal [true], lane.distributions
        assert_empty lane.uploads
      end
    end
    target = BetaLaneHarness.new.beta_export_target(true)
    assert_equal BetaLaneHarness::DISTRIBUTION_EXPORT_OPTIONS_PLIST, target[:export_options_plist]
    assert_equal File.join(BetaLaneHarness::BUILD_ROOT, "appstore"), target[:build_root]
    assert_equal File.join(BetaLaneHarness::ARCHIVE_ROOT, "appstore"), target[:archive_root]
  end

  def test_distribution_without_export_only_fails_before_archive_or_upload
    [{ distribution: true }, { distribution: "true", export_only: false }, { distribution: "yes", export_only: "no" }].each do |options|
      lane = BetaLaneHarness.new
      assert_raises(RuntimeError) { lane.upload_beta(:ios, options) }
      assert_empty lane.archives, "#{options.inspect} must fail before archiving"
      assert_empty lane.uploads, "#{options.inspect} must never upload"
    end
    [{ distribution: "maybe", export_only: true }, { distribution: "ture", export_only: true }, { distribuion: true, export_only: true }].each do |options|
      lane = BetaLaneHarness.new
      assert_raises(RuntimeError) { lane.upload_beta(:ios, options) }
      assert_empty lane.archives, "#{options.inspect} must fail before archiving"
      assert_empty lane.uploads, "#{options.inspect} must never upload"
    end
  end

  def test_distribution_artifacts_are_never_reuploaded_through_internal_path
    # A real file is needed because upload_beta checks File.file?; the folder is
    # gitignored and removed again.
    dir = File.join(BetaLaneHarness::BUILD_ROOT, "appstore", "ios", "test-#{Process.pid}")
    path = File.join(dir, "CanadianHam.ipa")
    FileUtils.mkdir_p(dir)
    File.write(path, "")
    lane = BetaLaneHarness.new
    error = assert_raises(RuntimeError) { lane.upload_beta(:ios, artifact_path: path) }
    assert_match(/distribution/, error.message)
    result = lane.upload_beta(:ios, artifact_path: path, export_only: true)
    assert_equal path, result[:artifact_path]
    assert_empty lane.archives
    assert_empty lane.uploads
  ensure
    FileUtils.rm_rf(dir) if dir
    [File.dirname(dir), File.dirname(dir, 2), File.dirname(dir, 3)].each do |parent|
      Dir.rmdir(parent) if Dir.exist?(parent) && Dir.empty?(parent)
    end if dir
  end

  def test_export_options_plists_differ_only_by_internal_only_flag
    internal = plist_json(BetaLaneHarness::EXPORT_OPTIONS_PLIST)
    distribution = plist_json(BetaLaneHarness::DISTRIBUTION_EXPORT_OPTIONS_PLIST)
    assert_equal true, internal["testFlightInternalTestingOnly"]
    refute distribution.key?("testFlightInternalTestingOnly"), "App Store export must not be internal-only"
    assert_equal internal.reject { |key, _| key == "testFlightInternalTestingOnly" }, distribution
    assert_equal "app-store-connect", distribution["method"]
  end

  private

  def plist_json(path)
    output, status = Open3.capture2("plutil", "-convert", "json", "-o", "-", path)
    assert status.success?, "plutil could not read #{path}"
    JSON.parse(output)
  end
end
