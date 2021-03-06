require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'
require 'active_support/inflector'
require 'byebug'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, params = {})
    @req = req
    @res = res
    @params = params
    @already_built_response = false
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise "Double render error" if already_built_response?

    @res = session.store_session(@res)

    @res.status = 302
    @res['location'] = url

    @already_built_response = true
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    content_type ||= 'text/html'
    raise "Double render error" if already_built_response?

    @res = session.store_session(@res)

    @res['Content-Type'] = content_type
    @res.write(content)
    @already_built_response = true
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    raise "Double render error" if already_built_response?

    controller_name = self.class.name.underscore
    path = File.dirname(__FILE__)
    new_path = File.join(path, "..", 'views', controller_name, "#{template_name}.html.erb")
    content = File.read(new_path)
    erb_template = ERB.new(content).result(binding)
    render_content(erb_template, 'text/html')
    @already_built_response = true
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(render(name))
  end
end
