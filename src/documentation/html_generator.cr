require "html"
require "./generator"

module HTML
  class Builder
    private getter io : IO

    def initialize(@io)
    end

    def document
      io << "<!DOCTYPE html>\n"
      element("html") { yield }
    end

    def element(name : String, content : String, **attributes)
      element(name, **attributes) { text(content) }
    end

    def element(name : String, **attributes)
      io << '<' << name
      attributes.each do |key, value|
        io << ' '
        key.to_s(io)
        io << "=\""
        HTML.escape(value, io)
        io << '"'
      end
      io << '>'
      yield
      io << "</" << name << '>'
    end

    def text(content : String)
      HTML.escape(content, io)
    end

    def raw(content : String)
      io.puts content
    end
  end

  def self.build(io : IO)
    html = Builder.new(io)
    html.document do
      yield html
    end
  end
end

module Runic
  class Documentation
    struct HTMLGenerator < Generator
      @git_hash : String
      @git_remote : String?

      def initialize(output : String)
        super output
        @git_hash = `git log -1 --pretty=format:%H 2>/dev/null`
        @git_remote = search_git_remote if $?.success?
      end

      private def search_git_remote
        `git remote -v`.split('\n').each do |remote|
          if idx = remote.index("github.com")
            if stop = remote.index('/', idx)
              if stop = remote.index('.', stop + 1)
                return remote[idx...stop].sub(':', '/')
              else
                return remote[idx..-1].sub(':', '/')
              end
            end
          end
        end
      end

      def generate(program : Program)
        # TODO: constants
        # TODO: externs

        toplevel = AST::Struct.new("toplevel", [] of String, "", Location.new("toplevel.runic"))
        program.functions.each { |_, node| toplevel.methods << node }
        generate(toplevel)

        program.structs.each { |_, node| generate(node) }
      end

      private def generate(node : AST::Struct)
        File.open(File.join(@output, "#{node.name}.html"), "w") do |io|
          document(io, title: node.name) do |html|
            html.element("div", id: "contents") do
              html.element("div") do

                html.element("h1") do
                  unless node.name == "toplevel"
                    if node.attribute?("primitive")
                      html.element("small", "primitive")
                    else
                      html.element("small", "struct")
                    end
                  end
                  html.text " "
                  html.text node.name
                end

                html.element("p") do
                  html.text node.documentation
                end

                # html.element("h2", "Functions", id: "#functions")

                node.methods.each do |fn|
                  html.element("article", id: "function-#{fn.name}") do
                    html.element("h3") do
                      html.element("code") { signature(html, fn) }
                      location(html, fn)
                    end

                    html.element("p") do
                      html.text fn.prototype.documentation
                    end
                  end
                end
              end
            end

            sidebar(html) do
              html.element("h2", "functions")
              node.methods.each { |fn| sidebar_entry(html, fn) }
            end
          end
        end
      end

      private def location(html : HTML::Builder, fn : AST::Function)
        if (commit = @git_hash) && (remote = @git_remote)
          if remote.starts_with?("github.com")
            href = "https://#{remote}/blob/#{commit}/#{fn.location.file}#L#{fn.location.line}"
          end
        end
        if href
          html.element("a", "</>", href: href, class: "view-source", title: fn.location.to_s)
        else
          html.element("a", "</>", class: "view-source", title: fn.location.to_s)
        end
      end

      private def signature(html : HTML::Builder, fn : AST::Function)
        html.text "def "
        html.element("a", fn.name, href: "#function-#{fn.name}")

        args = fn.args
        if args.first.try(&.name) == "self"
          (args = args.dup).shift
        end

        unless args.empty?
          html.text "("
          args.each_with_index do |arg, index|
            html.text ", " unless index == 0
            html.text arg.name
            html.text " : "
            html.element("a", arg.type.to_s, class: "type")
          end
          html.text ")"
        end

        html.text " : "
        html.element("a", fn.type.to_s, class: "type")
      end

      private def document(io : IO, title : String)
        HTML.build(io) do |html|
          html.element("head") do
            html.element("title", title)
            html.element("style") do
              html.raw <<-CSS
                * { font-family: inherit; }
                body {
                  display: grid;
                  min-height: 100vh;
                  padding: 0;
                  margin: 0;
                  -ms-grid-template-rows: 1fr;
                  -ms-grid-template-columns: 15% 1fr;
                  grid-template-rows: 1fr;
                  grid-template-columns: 15% 1fr;
                  font: 16px/26px Georgia, serif;
                }
                code {
                  font-family: Menlo, monospace;
                  font-size: 0.8em;
                }
                h1 { font-size: 26px; margin: 0 0 1em; }
                h1 small { font-size: 1rem; color: #6a6a6a; }
                h2 { font-size: 20px; }
                h3 { font-size: 16px; }
                h3, p { margin: 1em 0; }
                article {
                  margin: 1em 0 2em;
                  padding: 0 1em;
                }
                a { color: #78ab00; }

                #sidebar {
                  -ms-grid-row: 1;
                  -ms-grid-column: 1;
                  grid-row: 1;
                  grid-column: 1 / 2;
                  order: -1;
                  background: #383838;
                  color: #d8d8d8;
                  padding: 0 0 1em;
                }
                #sidebar h2 {
                  text-align: center;
                }
                #sidebar ul {
                  list-style: none;
                  padding-left: 0;
                  margin: 1em 0;
                }
                #sidebar a {
                  display: block;
                  padding: 0 1em;
                  color: #bacf00;
                }

                #contents {
                  -ms-grid-row: 1;
                  -ms-grid-column: 2;
                  grid-row: 1;
                  grid-column: 2 / 3;
                  max-width: 50em;
                  padding: 1em;
                }
                #contents h3 {
                  background: #f8f8f8;
                  padding: 0.5em 1em;
                  margin: -0.5em -1em;
                }

                .view-source {
                  float: right;
                  font-size: 14px;
                  color: #aaa;
                  text-decoration: none;
                }
                .view-source:hover {
                  color: #666;
                }

                .type {
                  color: #00bacf;
                }
                CSS
            end
          end

          html.element("body") do
            yield html
          end
        end
      end

      private def sidebar(html : HTML::Builder)
        html.element("nav", id: "sidebar") do
          html.element("ul") do
            yield
          end
        end
      end

      private def sidebar_entry(html : HTML::Builder, fn : AST::Function)
        html.element("li") do
          html.element("a", fn.name, href: "#function-#{fn.name}")
        end
      end
    end
  end
end
