JS_TEST_DRIVER_PORT = 4224

namespace :js do
  task :test => %w[js:test:run]

  namespace :test do
    desc "Run the JavaScript test server"
    task :server do
      system "cd public/javascripts && java -jar spec/JsTestDriver.jar --port #{JS_TEST_DRIVER_PORT}"
    end

    desc "Reset the JavaScript test server"
    task :reset do
      system "cd public/javascripts && java -jar spec/JsTestDriver.jar --reset"
    end

    desc "Capture the default browser for JavaScript testing"
    task :capture do
      system "open http://localhost:#{JS_TEST_DRIVER_PORT}/capture"
    end

    desc "Run the JavaScript tests"
    task :run do
      system "cd public/javascripts && java -jar spec/JsTestDriver.jar --tests all #{'--verbose --captureConsole' if ENV['VERBOSE']}"
    end
  end
end
