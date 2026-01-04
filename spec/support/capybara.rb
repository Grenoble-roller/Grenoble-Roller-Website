# Capybara configuration for system/feature tests
require 'capybara/rails'
require 'capybara/rspec'
require 'selenium-webdriver'

# Configure Capybara defaults
Capybara.default_max_wait_time = 5
Capybara.server_port = 3001
Capybara.server_host = '0.0.0.0'

# Register headless Chrome driver for system tests with JavaScript
# This driver will be used by Rails' driven_by helper in rails_helper.rb
# selenium-webdriver 4.x gère automatiquement ChromeDriver via webdriver-manager
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1400,1400')
  options.add_argument('--disable-features=VizDisplayCompositor')
  # Utiliser le service ChromeDriver automatique (selenium-webdriver 4.x)
  service = Selenium::WebDriver::Service.chrome

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, service: service)
end
