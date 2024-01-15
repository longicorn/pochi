#!/bin/env ruby

require 'optparse'
require 'date'
require 'ferrum'
require 'yaml'

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

def stamp(driver, worktype:, datetime:, is_stamp: false)
  elements = driver.at_css('[id=sidemenu]').css('a')
  element = elements.detect{|e|e.text == '打刻修正'}
  element.click
  wait_url(driver, "#{BASE_URL}/employee/adit/modify/")

  # set date
  if datetime.to_date != Date.today
    elements = driver.at_css('[id=search-box]').css('select')
    element = elements.detect{|e|e.attribute('name')=='year'}
    element.select(datetime.year.to_s)
    element = elements.detect{|e|e.attribute('name')=='month'}
    element.select(datetime.month.to_s)
    element = elements.detect{|e|e.attribute('name')=='day'}
    element.select(datetime.day.to_s)

    elements = driver.at_css('[id=search-box]').css('a')
    element = elements.detect{|e|e.text == '表示'}
    element.click
    sleep 0.5
  end

  # set work type
  element = driver.at_css('[id=adit_item_change]').at_css('select')
  type_option = {start: 'work_start', finish: 'work_end'}[worktype.to_sym]
  element.select(type_option)

  # set work time
  element = driver.at_css('[id=ter_time]')
  element.focus.type(datetime.strftime("%H:%M"))
  sleep 0.5

  # stamp!
  if is_stamp
    puts 'stamp!'
    element = driver.at_css('[id=insert_button]')
    element.click
    sleep 0.5
  end
end

arg_hash = {datetime: DateTime.now}
params = ARGV.getopts('t:d:', 'type:', 'datetitme:')
params.each_key do |key|
  next unless params[key]

  case key
  when 't', 'type'
    type = {start: :start, s: :start, finish: :finish, f: :finish}[params[key].to_sym]
    arg_hash[:type] = type
  when 'd', 'datetime'
    arg_hash[:datetime] = DateTime.parse(params[key])
    raise if Date.today < arg_hash[:datetime].to_date
  end
end

browser = Ferrum::Browser.new
browser.resize(width: 1000, height: 1300)
login(browser)
browser.screenshot(path: "screenshot.png")
stamp(browser, worktype: arg_hash[:type], datetime: arg_hash[:datetime], is_stamp: true)
browser.screenshot(path: "screenshot.png")
