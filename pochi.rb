#!/usr/bin/env ruby

require 'yaml'
require 'ferrum'

def wait_url(driver, url)
  100.times do
    break if driver.current_url == url
    sleep 0.1
  end
end

BASE_URL = 'https://id.jobcan.jp'
def read_setting
  yml = File.read('setting.yml')
  setting_yaml = YAML.load(yml)
  email = setting_yaml['service']['jobcan']['email']
  password = setting_yaml['service']['jobcan']['password']

  {email: email, password: password}
end

def login(driver)
  login_url = "#{BASE_URL}/users/sign_in?app_key=atd"
  setting = read_setting

  driver.go_to(login_url)

  element = driver.at_css('[id=user_email]')
  element.focus.type(setting[:email])

  element = driver.at_css('[id=user_password]')
  element.focus.type(setting[:password])

  element = driver.at_css('[id=login_button]')
  element.click

  driver.screenshot(path: "screenshot.png")
  wait_url(driver, "#{BASE_URL}/employee")
  raise if driver.current_url == login_url
end

def stamp(driver, type)
  case type
  when :start
    node = driver.at_css('button#adit-button-work-start')
  when :finish
    node =  driver.at_css('button#adit-button-work-end')
  end
  raise if node.nil?
  node.focus.click
end

option = ARGV.shift
type = {s: :start, f: :finish}[option.sub(/^-/, '').to_sym]

browser = Ferrum::Browser.new
browser.resize(width: 1000, height: 1300)
login(browser)
stamp(browser, type)
sleep 1
browser.screenshot(path: 'screenshot.png')
