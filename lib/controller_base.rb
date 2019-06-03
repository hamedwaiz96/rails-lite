require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @params = route_params.merge(req.params)
    @already_built_response = false
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    if @already_built_response
      raise 'double render'
    else
      @res['Location'] = url
      @res.status = 302
      @already_built_response = true
      session.store_session(@res)
    end
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    if @already_built_response
      raise 'double render'
    else
      @res['Content-Type'] = content_type
      @res.write(content)
      @res.finish
      @already_built_response = true
      session.store_session(@res)
    end
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    controller_name = self.class.name.underscore
    template = "#{template_name}.html.erb"
    directory = File.dirname("views/#{controller_name}/#{template}")
    file = File.join(directory, template)
    read = File.read(file)
    new_template = ERB.new(read).result(binding)
    render_content(new_template, 'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    render(name) unless already_built_response?
    nil
  end
end

