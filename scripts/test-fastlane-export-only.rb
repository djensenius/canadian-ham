#!/usr/bin/env ruby
require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "tmpdir"

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
  # The real method, for ExportArgsHarness; the stub below replaces it here.
  alias_method :fastfile_archive_and_export, :archive_and_export

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

# Runs the Fastfile's real archive_and_export with the keychain and xbuild
# stubbed: records each xbuild argument list and fakes the exported artifacts.
class ExportArgsHarness < BetaLaneHarness
  attr_reader :xbuild_calls

  def initialize
    super
    @xbuild_calls = []
  end

  def archive_and_export(platform_key, official_reference_sheet:, distribution: false)
    fastfile_archive_and_export(platform_key, official_reference_sheet: official_reference_sheet, distribution: distribution)
  end

  def unlock_build_keychain; end

  def run_xbuild(args)
    @xbuild_calls << args
    return unless args.first == "-exportArchive"

    export_path = args[args.index("-exportPath") + 1]
    %w[ipa pkg].each { |extension| File.write(File.join(export_path, "CanadianHam.#{extension}"), "") }
  end
end

class FastlaneExportOnlyTests < Minitest::Test
  ROOT_CONSTANTS = %i[ARCHIVE_ROOT BUILD_ROOT DISTRIBUTION_ARCHIVE_ROOT DISTRIBUTION_BUILD_ROOT].freeze

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
    with_temp_roots do |dir|
      path = write_artifact(File.join(BetaLaneHarness::DISTRIBUTION_BUILD_ROOT, "ios", "202611020000"))
      file_link = File.join(dir, "linked.ipa")
      File.symlink(path, file_link)
      folder_link = File.join(dir, "elsewhere")
      File.symlink(BetaLaneHarness::DISTRIBUTION_BUILD_ROOT, folder_link)
      aliases = [path, file_link, File.join(folder_link, "ios", "202611020000", "CanadianHam.ipa")]
      case_variant = path.sub("/appstore/", "/AppStore/")
      aliases << case_variant if File.file?(case_variant) # case-insensitive volumes only
      aliases.each do |artifact|
        lane = BetaLaneHarness.new
        error = assert_raises(RuntimeError) { lane.upload_beta(:ios, artifact_path: artifact) }
        assert_match(/Refusing to upload App Store distribution export/, error.message, artifact)
        result = lane.upload_beta(:ios, artifact_path: artifact, export_only: true)
        assert_equal File.expand_path(artifact), result[:artifact_path]
        assert_empty lane.archives
        assert_empty lane.uploads, "#{artifact} must never upload"
      end
    end
  end

  def test_internal_artifacts_still_upload_when_distribution_folder_exists_or_not
    with_temp_roots do |dir|
      path = write_artifact(File.join(BetaLaneHarness::BUILD_ROOT, "ios", "202611020000"))
      link = File.join(dir, "internal-link.ipa")
      File.symlink(path, link)
      [path, link].each do |artifact|
        lane = BetaLaneHarness.new
        lane.upload_beta(:ios, artifact_path: artifact)
        assert_equal [File.expand_path(artifact)], lane.uploads.map { |upload| upload[:ipa] }
      end
      write_artifact(File.join(BetaLaneHarness::DISTRIBUTION_BUILD_ROOT, "ios", "1"))
      lane = BetaLaneHarness.new
      lane.upload_beta(:ios, artifact_path: path)
      assert_equal 1, lane.uploads.length
    end
  end

  def test_export_options_plist_reaches_the_export_arguments
    with_temp_roots do |dir|
      [:ios, :mac, :appletvos, :xros].each do |platform|
        [[{}, BetaLaneHarness::EXPORT_OPTIONS_PLIST, BetaLaneHarness::ARCHIVE_ROOT, BetaLaneHarness::BUILD_ROOT, true],
         [{ distribution: true }, BetaLaneHarness::DISTRIBUTION_EXPORT_OPTIONS_PLIST,
          BetaLaneHarness::DISTRIBUTION_ARCHIVE_ROOT, BetaLaneHarness::DISTRIBUTION_BUILD_ROOT, false]].each do |options, plist, archive_root, build_root, official|
          lane = ExportArgsHarness.new
          result = lane.upload_beta(platform, options.merge(export_only: true))
          archive, export = lane.xbuild_calls
          assert_equal 2, lane.xbuild_calls.length
          assert_includes archive, "archive"
          assert archive[archive.index("-archivePath") + 1].start_with?(File.join(archive_root, platform.to_s) + File::SEPARATOR)
          assert_equal official, archive.any? { |arg| arg.include?("OFFICIAL_REFERENCE_SHEET") }, "#{platform} #{options.inspect}"
          refute archive.any? { |arg| arg.include?("ICLOUD_SYNC") || arg.include?("DebugCloudKit") }
          assert_includes archive, "-configuration"
          assert_equal "Release", archive[archive.index("-configuration") + 1]
          assert_equal "-exportArchive", export.first
          assert_equal plist, export[export.index("-exportOptionsPlist") + 1], "#{platform} #{options.inspect}"
          assert_equal archive[archive.index("-archivePath") + 1], export[export.index("-archivePath") + 1]
          assert export[export.index("-exportPath") + 1].start_with?(File.join(build_root, platform.to_s) + File::SEPARATOR)
          assert result[:artifact_path].start_with?(build_root + File::SEPARATOR)
          assert_empty lane.uploads
        end
      end
      assert Dir.exist?(File.join(dir, "builds")), "exports must stay in the temporary roots"
    end
  end

  def test_distribution_archive_refuses_the_official_sheet
    with_temp_roots do
      lane = ExportArgsHarness.new
      error = assert_raises(RuntimeError) { lane.fastfile_archive_and_export(:ios, official_reference_sheet: true, distribution: true) }
      assert_match(/must not opt in to the internal-only official reference sheet/, error.message)
      assert_empty lane.xbuild_calls
    end
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

  # Points the Fastfile's archive and export roots at a temporary folder, so no
  # test writes to the real fastlane/archives or fastlane/builds.
  def with_temp_roots
    Dir.mktmpdir("fastlane-export-only-test") do |dir|
      roots = {
        ARCHIVE_ROOT: File.join(dir, "archives"),
        BUILD_ROOT: File.join(dir, "builds"),
        DISTRIBUTION_ARCHIVE_ROOT: File.join(dir, "archives", "appstore"),
        DISTRIBUTION_BUILD_ROOT: File.join(dir, "builds", "appstore")
      }
      saved = ROOT_CONSTANTS.to_h { |name| [name, BetaLaneHarness.const_get(name)] }
      begin
        roots.each { |name, value| replace_constant(name, value) }
        yield dir
      ensure
        saved.each { |name, value| replace_constant(name, value) }
      end
    end
  end

  def replace_constant(name, value)
    BetaLaneHarness.send(:remove_const, name)
    BetaLaneHarness.const_set(name, value)
  end

  def write_artifact(dir)
    FileUtils.mkdir_p(dir)
    path = File.join(dir, "CanadianHam.ipa")
    File.write(path, "")
    path
  end

  def plist_json(path)
    output, status = Open3.capture2("plutil", "-convert", "json", "-o", "-", path)
    assert status.success?, "plutil could not read #{path}"
    JSON.parse(output)
  end
end
