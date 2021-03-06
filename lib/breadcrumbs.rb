module Breadcrumbs
  class Crumb
    attr_reader :name, :url

    def initialize(name, url = nil)
      @name, @url = name, url
    end
  end

  module InstanceMethods
    protected
    # Append a breadcrumb to the end of the trail
    def add_breadcrumb(name, url = nil)
      breadcrumbs << Crumb.new(name, url)
    end

    def breadcrumbs
      @breadcrumbs ||= []
    end
  end

  module ClassMethods
    # Append a breadcrumb to the end of the trail.  A symbol will be evaluated in the context of the controller instance.
    def add_breadcrumb(name, url = nil, options = {})
      before_filter(options) do |controller|
        controller.instance_eval do
          url = __send__(url) if url.is_a?(Symbol)
          name = __send__(name).to_s.titleize if name.is_a?(Symbol)
          add_breadcrumb(name, url)
        end
      end
    end
  end

  module HelperMethods
    # Returns HTML markup for the breadcrumbs
    def render_breadcrumbs(options = {})
      if options[:partial]
        render({:collection => breadcrumbs}.merge(options))
      else
        options = {:separator => "&nbsp;&raquo;&nbsp;"}.merge(options)
        breadcrumbs.map do |crumb|
          str = link_to_unless_current(crumb.name, crumb.url)
          options[:tag] ? content_tag(options[:tag], str) : str
        end.join(options[:separator])
      end
    end
  end
end

class ActionController::Base
  include Breadcrumbs::InstanceMethods
  helper_method :add_breadcrumb
  helper_method :breadcrumbs
end

ActionController::Base.extend(Breadcrumbs::ClassMethods)
ActionView::Base.send(:include, Breadcrumbs::HelperMethods)