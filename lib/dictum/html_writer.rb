require_relative 'html_helpers'
require 'json'

module Dictum
  class HtmlWriter
    attr_reader :temp_path, :temp_json, :output_dir, :output_file, :output_title

    def initialize(output_dir, temp_path, output_title)
      @output_dir = output_dir
      @temp_path = temp_path
      @temp_json = JSON.parse(File.read(temp_path))
      @output_title = output_title
    end

    def write
      Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
      write_index
      write_pages
    end

    private

    def write_index
      html = HtmlHelpers.build do |b|
        content = "<div class='jumbotron'>\n#{HtmlHelpers.title('Index', 'title')}\n</div>\n"
        content += b.unordered_list(temp_json.keys)

        container = b.re_container(b.row(content))
        b.html_header(output_title, container)
      end
      index = File.open("#{output_dir}/index.html", 'w+')
      index.puts html
      index.close
    end

    def write_pages
      temp_json.each do |resource_name, information|
        html = HtmlHelpers.build do |b|
          content = b.title(resource_name, 'title')
          content += b.paragraph(information['description'])
          content += write_endpoints(information['endpoints'], b)

          container = b.re_container(b.row(content) + b.row(b.button('Back', 'glyphicon-menu-left')))
          b.html_header(output_title, container)
        end
        file = File.open("#{output_dir}/#{resource_name.downcase}.html", 'w+')
        file.puts html
        file.close
      end
    end

    def write_endpoints(endpoints, builder)
      endpoints.each_with_object('') do |endpoint, answer|
        answer += builder.subtitle("#{endpoint['http_verb']} #{endpoint['endpoint']}")
        answer += builder.paragraph(endpoint['description'])
        answer += write_request_parameters(endpoint, builder)
        answer += write_response(endpoint, builder)
        answer
      end
    end

    def write_request_parameters(endpoint, builder)
      write_codeblock('Request headers', endpoint['request_headers'], builder) +
        write_codeblock('Request path parameters', endpoint['request_path_parameters'], builder) +
        write_codeblock('Request body parameters', endpoint['request_body_parameters'], builder)
    end

    def write_response(endpoint, builder)
      answer = write_codeblock('Status', endpoint['response_status'], builder)
      answer += write_codeblock(
        'Response headers', endpoint['response_headers'], builder
      ) if endpoint['response_headers']

      if endpoint['response_body']
        param = (endpoint['response_body'] == 'no_content') ? {} : endpoint['response_body']
        answer += write_codeblock('Response body', param, builder)
      end
      answer
    end

    def write_codeblock(text, json, builder)
      return unless text && json && builder
      builder.code_block(text, JSON.pretty_generate(json))
    end
  end
end
