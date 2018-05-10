# -*- coding: UTF-8 -*-
require 'redmine'
require_dependency 'msg_issues_hook'

Redmine::Plugin.register :iss_notifylink do
  name '问题触发链接'
  author '余渊<yuyuan@qq.com>'
  description '此项目是为ops定制的redmine消息插件，当问题创建或是编辑，就会触发链接数据提交，提交的内容有receivers(接收者)，title(标题)，message(消息，腾讯通信息格式),receiver_type(接收者类型，badge)'
  version '0.0.1'
  url 'https://github.com/Apuyuseng/iss_notifylink'
  author_url 'https://github.com/Apuyuseng'
  settings :default => {
    :add_notify                      => true,
    :edit_notify                     => true,
    :user                            => 'admin',
    :password                        => 'admin',
    :msg_api_url                     => 'http://192.168.24.211:7000/'
  },:partial => 'settings/msg_settings'
end
