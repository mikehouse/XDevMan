@testable import XDevMan
import Foundation
import Testing

@MainActor
struct FastfileParserTests {
    
    @Test
    func parseAssignedAndForwardedLaneOptions() async throws {
        let fastfile = """
        platform :ios do
          lane :ui_tests_kyc_integration do |options|
            options[:testplan] = "KYC"
            options[:allure_run_name] = "ios KYC integration tests"
            options[:build_type] = "integration"
            ui_tests(options)
          end

          lane :ui_tests do |options|
            testplan = options[:testplan]
            simulator_mode = options[:simulator_mode]
            Thread.current[:id] = options[:id].nil? ? nil : Integer(options[:id])
            setup_simulator_skip = options[:setup_simulator_skip].nil? ? false : options[:setup_simulator_skip]
            rebuild_test_bundle = options[:rebuild_test_bundle].nil? ? false : options[:rebuild_test_bundle]
            allure_upload = options[:allure].nil? ? true : options[:allure]
            slack = options[:slack].nil? ? true : options[:slack]
            device = options[:device].nil? ? ui_tests_base_device : options[:device]
            project_dir = Pathname.getwd.parent
            products_path = "#{project_dir}/#{ui_tests_products_path}"
          end
        end
        """
        let readme = """
        fastlane documentation
        ----

        # Available Actions

        ### ui_tests_kyc_integration

        [bundle exec] fastlane ui_tests_kyc_integration

        ----

        This README.md is auto-generated and will be re-generated every time
        """
        
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fastlaneDir = root.appendingPathComponent("fastlane", isDirectory: true)
        try FileManager.default.createDirectory(at: fastlaneDir, withIntermediateDirectories: true)
        try fastfile.write(to: fastlaneDir.appendingPathComponent("Fastfile"), atomically: true, encoding: .utf8)
        try readme.write(to: fastlaneDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: root)
        }
        
        let service = FastlaneService(bashService: BashProviderMock.self)
        let result = try await service.scan(root)
        
        #expect(result.lanes.count == 1)
        let lane = try #require(result.lanes.first)
        #expect(lane.name == "ui_tests_kyc_integration")
        
        let options = Dictionary(uniqueKeysWithValues: lane.inputs.map({ ($0.name, $0.type) }))
        #expect(options.count == 10)
        #expect(options["testplan"] == .string)
        #expect(options["allure_run_name"] == .string)
        #expect(options["build_type"] == .string)
        #expect(options["simulator_mode"] == .string)
        #expect(options["id"] == .string)
        #expect(options["setup_simulator_skip"] == .bool)
        #expect(options["rebuild_test_bundle"] == .bool)
        #expect(options["allure"] == .bool)
        #expect(options["slack"] == .bool)
        #expect(options["device"] == .string)
    }
    
    @Test
    func parseComplexAssignedAndForwardedLaneOptions() async throws {
        let fastfile = """
        platform :ios do
          lane :ui_tests_kyc_integration do |options|
            options[:testplan] = "KYC"
            options[:allure_run_name] = "ios KYC integration tests"
            options[:build_type] = "integration"
            ui_tests(options)
          end

          lane :ui_tests do |options|
            testplan = options[:testplan]
            simulator_mode = options[:simulator_mode]
            Thread.current[:id] = options[:id].nil? ? nil : Integer(options[:id])
            setup_simulator_skip = options[:setup_simulator_skip].nil? ? false : options[:setup_simulator_skip]
            rebuild_test_bundle = options[:rebuild_test_bundle].nil? ? false : options[:rebuild_test_bundle]
            allure_upload = options[:allure].nil? ? true : options[:allure]
            slack = options[:slack].nil? ? true : options[:slack]
            device = options[:device].nil? ? ui_tests_base_device : options[:device]
            project_dir = Pathname.getwd.parent
            products_path = "#{project_dir}/#{ui_tests_products_path}"
            if File.directory?(products_path) == false || rebuild_test_bundle
              build_ui_tests_products
            else
              setup_xcode_current_build
            end
            if setup_simulator_skip == false
              setup_simulator_app
            end
            runtime = options[:runtime]
            if runtime == nil || runtime == ""
              runtime = xcode_current_sdk
            end

            testrun_path = Dir.glob("#{products_path}/Tests/*/#{testplan}.xctestrun")[0]
            if options[:localhost_port].nil? == false && options[:localhost_port] != ""
              sh "/usr/libexec/PlistBuddy -c \"Delete :TestConfigurations:0:TestTargets:0:EnvironmentVariables:LOCALHOST_PORT string\" '#{testrun_path}' || true"
              sh "/usr/libexec/PlistBuddy -c \"Add :TestConfigurations:0:TestTargets:0:EnvironmentVariables:LOCALHOST_PORT string '#{Integer(options[:localhost_port])}'\" '#{testrun_path}'"
            end

            run_tests = true
            rerun_count = 0
            while run_tests do
              run_tests = false
              result_bundle_name = "Test-#{project_name}UITests-#{Time.now.strftime("%Y.%m.%d_%H-%M-%S-%6N-%z")}.xcresult"
              result_bundle_path = "#{project_dir}/fastlane/test_output/#{result_bundle_name}"
              allure_launch_id = ""
              failure = ""

              simulators = []
              destinations = []
              (0..0).each do
                simulator = simulator_device_ui_tests_reusable(runtime, device)
                if simulator == nil
                  UI.user_error!("Simulator not found for runtime=#{runtime},name=#{device}")
                end
                simulator_uuid = simulator[:uuid]
                destinations.push("platform=iOS Simulator,id=#{simulator_uuid}")
                simulator_device_do_lock(simulator_uuid)
                simulators.push(simulator)

                if simulator[:shutdown] == false
                  sh "xcrun simctl uninstall #{simulator_uuid} com.apple.example || true"
                end
              end

              begin
                if simulator_mode != nil && simulator_mode == "appsflyer-deeplink"
                  if simulators.size != 1
                    UI.user_error!("Only 1 simulator supported for appsflyer deeplink tests")
                  end
                  simulator = simulators.first
                  simulator_uuid = simulator[:uuid]
                  if simulator[:shutdown] == true
                    UI.user_error!("UI tests failed, simulator is in shutdown state, please boot it first.")
                  end
                end

                run_tests(
                  package_path: "",
                  testplan: testplan,
                  skip_detect_devices: true,
                  number_of_retries: 1,
                  code_coverage: false,
                  result_bundle: true,
                  result_bundle_path: result_bundle_path,
                  parallel_testing: false,
                  test_without_building: true,
                  destination: destinations,
                  output_types: "",
                  derived_data_path: products_path,
                  xcargs: "-testProductsPath '#{products_path}'"
                )
              rescue => e
                puts "fastlane run_tests(...) error thrown: #{e}"
                if File.exist?(result_bundle_path) && rerun_count == 0
                  begin
                    failure_maybe_info = xcresult_info_print(result_bundle_path)
                    if failure_maybe_info.include?("Test crashed with signal term.") || failure_maybe_info.include?("System Failures (0)")
                      sh "rm -fr '#{result_bundle_path}'"
                      run_tests = true
                      rerun_count += 1
                      puts "Rerun tests one more time as found unexpected Simulator termination event."
                      next
                    end
                  rescue => e
                    puts e
                  end
                end
                failure = "#{e.message}"
              ensure
                simulators.each do |simulator|
                  simulator_device_do_unlock(simulator[:uuid])
                end
              end
              if allure_upload
                begin
                  allure_launch_id = allure(
                    convert: true,
                    device: device,
                    modify: true,
                    allure_run_name: options[:allure_run_name],
                    upload: true,
                    xcresult: result_bundle_path
                  )
                  puts "https://apple.io/launch/" + allure_launch_id
                rescue => e
                  failure = "#{e.message}"
                end
              end
              if slack
                slack_send(failure, failure != "") { |payload|
                  payload.store("Allure launch", "https://allure.apple.io/launch/" + allure_launch_id)
                }
              end
              if failure != ""
                UI.user_error!("UI tests failed")
              end
            end
          end
        
          lane :allure do |options|
            allure_run_name = options[:allure_run_name].nil? ? "ios tests" : options[:allure_run_name]
            device = options[:device].nil? ? "Unknown device" : options[:device]
            convert = options[:convert].nil? ? false : options[:convert]
            modify = options[:modify].nil? ? false : options[:modify]
            upload = options[:upload].nil? ? false : options[:upload]
            xcresult = options[:xcresult]
            allure_launch_id = ""
            if File.exist?("allure.txt")
              sh("rm -rf allure.txt")
            end
          end
        end
        """
        let readme = """
        fastlane documentation
        ----

        # Available Actions

        ### ui_tests_kyc_integration

        [bundle exec] fastlane ui_tests_kyc_integration

        ----

        This README.md is auto-generated and will be re-generated every time
        """
        
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fastlaneDir = root.appendingPathComponent("fastlane", isDirectory: true)
        try FileManager.default.createDirectory(at: fastlaneDir, withIntermediateDirectories: true)
        try fastfile.write(to: fastlaneDir.appendingPathComponent("Fastfile"), atomically: true, encoding: .utf8)
        try readme.write(to: fastlaneDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: root)
        }
        
        let service = FastlaneService(bashService: BashProviderMock.self)
        let result = try await service.scan(root)
        
        #expect(result.lanes.count == 1)
        let lane = try #require(result.lanes.first)
        #expect(lane.name == "ui_tests_kyc_integration")
        
        let options = Dictionary(uniqueKeysWithValues: lane.inputs.map({ ($0.name, $0.type) }))
        #expect(options.count == 12)
        #expect(options["testplan"] == .string)
        #expect(options["allure_run_name"] == .string)
        #expect(options["build_type"] == .string)
        #expect(options["simulator_mode"] == .string)
        #expect(options["id"] == .string)
        #expect(options["setup_simulator_skip"] == .bool)
        #expect(options["rebuild_test_bundle"] == .bool)
        #expect(options["allure"] == .bool)
        #expect(options["slack"] == .bool)
        #expect(options["device"] == .string)
        #expect(options["runtime"] == .string)
        #expect(options["localhost_port"] == .string)
    }
}
