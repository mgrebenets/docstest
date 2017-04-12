#!/usr/bin/env ruby

require "json"
require "pp"

def usage
  puts "Usage: #{File.basename(__FILE__)} PODSPECS_PATH [DATA_PATH]"
  exit 2
end

usage unless ARGV[0]

# TODO: Refactor later to use option parser and add support for overwrite option
options = {}
options[:path] = File.expand_path(ARGV[0])
options[:data_path] = ARGV[1] ? File.expand_path(ARGV[1]) : "_data"
options[:overwrite] = false

def load_pods_info(path:, default_value: {})
  File.exist?(path) ? JSON.parse(File.read(path)) : default_value
end

# Pods that have been renamed, so old names are obsolete
renamed_pods = ["Accounts", "Authentication", "Customer", "Breadcrumbs", "Cards", "FloatingTextField", "Observables", "Services"]
# External pods
external_pods = %w[AFNetworking Alamofire ALDColorBlindEffect AppDynamicsAgent
                   BFWControls BFWDrawView BFWQuery BlueCatsSDK Expecta FMDB
                   Kiwi Masonry OCMock Reachability ReactiveCocoa Realm RealmSwift
                   Result RPFloatingPlaceholders SDWebImage SplunkMint SQLCipher sqlite3
                   SVProgressHUD TBXML ValueCoding XMLDictionary ZXingObjC]
# Obsolete pods, not used any more
obsolete_pods = ["Analytics", "DigitalPlatformSDK"]
# Legacy pods, still used but should be removed when possible
legacy_pods = ["HelixKit", "AAAKit", "KIALib", "Switchblade.FeatureSwitch", "MyTestAnywhere"]
# Extra directories and other noise
extra_dirs = ["docs", "MGFramework", "AAAAnalytics.ios"]
# Self hosted external pods (external pods for which we create and maintain the podspec)
self_hosted_pods = ["AdobeMobileExtensionSDK-Framework", "AdobeMobileSDK",
                    "AdobeMobileSDK-Framework", "AdobeMobileTVSDK-Framework",
                    "AdobeMobileWatchSDK-Framework", "KofaxMobileSDK", "libBlueCatsSDK"]
# Resources pods (pods that are used to bundle up and provide resources)
resources_pods = ["HelixMockResponses"]

# Pods to ginore
ignored_pods = renamed_pods + external_pods + obsolete_pods + extra_dirs

# Initial value
initial_value = {
  "platforms" => {
    "ios" => {
      "title" => "iOS Frameworks",
      "description" => "Native frameworks for Apple iOS platform",
      "categories" => {
        "internal" => {
          "title" => "Internal",
          "description" => "Internal AAA frameworks",
          "frameworks" => {}
        },
        "self_hosted" => {
          "title" => "Self-Hosted",
          "description" => "External frameworks for which AAA creates and maintains podspecs",
          "frameworks" => {}
        },
        "resources" => {
          "title" => "Resources",
          "description" => "CocoaPods used to bundle and provide resources",
          "frameworks" => {}
        },
        "legacy" => {
          "title" => "Legacy",
          "description" => "Legacy pods, still used but should be removed when possible",
          "frameworks" => {}
        }
      }
    },
    "android" => {
      "title" => "Android Frameworks",
      "description" => "Native frameworks for Goole Android platform",
      "categories" => {}
    }
  }
}

# Read existing entries
data_path = options[:data_path]
frameworks_data_path = File.join(data_path, "frameworks.json")
frameworks_info = if options[:overwrite]
                    initial_value
                  else
                    load_pods_info(path: frameworks_data_path, default_value: initial_value)
                    end

ios_categories = frameworks_info["platforms"]["ios"]["categories"]

Dir["#{options[:path]}/*"].each do |pod_dir|
  name = File.basename(pod_dir)
  next if ignored_pods.include?(name)
  puts "Pod: #{name}..."

  # Select the right pods info hash to update
  category = if legacy_pods.include?(name) then ios_categories["legacy"]
             elsif self_hosted_pods.include?(name) then ios_categories["self_hosted"]
             elsif resources_pods.include?(name) then ios_categories["resources"]
             else ios_categories["internal"]
             end

  frameworks = category["frameworks"]
  # Create entry if doesn't exist
  frameworks[name] ||= {}

  # Collect versions JSONs
  Dir["#{pod_dir}/*"].each do |version_dir|
    version = File.basename(version_dir)
    puts "- #{version}"

    framework_hash = frameworks[name]
    # Set if not yet there or if overwrite option is set
    framework_hash["versions"] ||= []

    # Skip if the entry for this version exists
    version_included = framework_hash["versions"].any? { |entry| entry.keys.first == version }
    next if version_included

    # Read podspec as JSON
    podspec = Dir["#{version_dir}/*.podspec"].first
    framework_hash["versions"] << { version => JSON.parse(`pod ipc spec #{podspec}`.chomp) }

    # Fetch documentation
    # fetch_doco(
    #   name: name,
    #   version: version,
    #   spec: pods_info[name][version],
    #   data_path: options[:data_path],
    #   overwrite: options[:overwrite]
    # )
  end

  # TODO:
end

# # Fetch documentation for current pod
# def fetch_doco(name:, version:, spec:, data_path:, overwrite: false)
#   target_path = File.join(data_path, "docs", "")
#   # First check the documentation URL in the spec and try to get it if possible
# end

# Write output to Jekyll data folder
File.open(frameworks_data_path, "w") { |f| f.puts frameworks_info.to_json }
