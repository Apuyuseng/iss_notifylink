# -*- coding: UTF-8 -*-
class MSGIssueHook < Redmine::Hook::ViewListener
	include IssuesHelper
	include CustomFieldsHelper
	
	def initialize
		$msg_hook = self
	end
	
	def controller_issues_new_after_save(context={})
		return unless self.class.get_setting(:add_notify)
		issue = context[:issue]
		title = l(:label_issue_added)
		content = l(:text_issue_added, :id => "##{issue.id}", :author => issue.author)
		issueUrl = redmine_url(:controller => 'issues', :action => 'show', :id => issue)
		send_msg(issue, title, content, issueUrl)
	end
	
	def controller_issues_edit_after_save(context={})
		return unless self.class.get_setting(:edit_notify)
		issue = context[:issue]
		journal = context[:journal]
		title = l(:label_issue_updated)
		content = l(:text_issue_updated, :id => "##{issue.id}", :author => journal.user)
		details_to_strings(journal.details, true).each do |string|
			content += "\n  " + string
		end
		content += "\n" + journal.notes if journal.notes?
		
		issueUrl = redmine_url(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")
		send_msg(issue, title, content, issueUrl)
	end
	
	def send_msg(issue, title, content, issueUrl)
		userAry = ([issue.assigned_to] | issue.watcher_users).select{ |u| u.respond_to? :login }
		return if userAry.empty?
		msgAry = userAry.map(&:login)
		# Modify these liens yourself to change the title style.
		#subject = to_msg_str(issue_heading(issue))
		subject = to_msg_str("(#{issue.status.name}) ##{issue.id} #{issue.subject}")
		content = to_msg_str(content)
		msg = "[#{subject} |#{issueUrl}]\n#{content}"
	    param = {:receivers => msgAry, :title => title, :message => msg, :receiver_type => :badge}
		self.class.call_msg(param)
	end
	
	def redmine_url(param)
		param[:host] = Setting.host_name
		param[:protocol] = Setting.protocol
		url_for(param)
	end
	
	def self.call_msg(param)
	    if get_setting(:msg_api_url)
            uri = URI.parse(Setting["plugin_#{plugin.id}"]["msg_api_url"])
            username=Setting["plugin_#{plugin.id}"]["user"]
            password=Setting["plugin_#{plugin.id}"]["password"]
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true  # https 需要加这个，对于这个真的蛋疼
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE # https 需要加这个
            request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
            request.basic_auth(username, password)
            request.body = param.to_json
            response = http.request(request)
            Rails.logger.info "MSG_RESPONSE: #{response.code} #{response.message}"
        end
	end
	
	def self.plugin
		Redmine::Plugin.find(:iss_notifylink) #init.rb　注册的名字
	end
	
	def self.get_setting(name)
	  begin
	    if plugin
	      if Setting["plugin_#{plugin.id}"]
	        Rails.logger.info Setting["plugin_#{plugin.id}"][name]
	      else
	        if plugin.settings[:default].has_key?(name)
	          plugin.settings[:default][name]
	        end
	      end
	    end
	  rescue
	    nil
	  end
	end
	
	def to_msg_str(str)
		str.sub! '[', '{'
		str.sub! ']', '}'
		str.sub! '<', '{'
		str.sub! '>', '}'
		str.sub! '|', '!'
		str
	end
	
	def self.iconv(to, from, str)
		if str.respond_to?(:encode)	# for Ruby ver. 1.9.0 and above
			str.encode('GBK', from)
		else
			Iconv.conv(to+'//IGNORE', from, str)
		end
	end
end