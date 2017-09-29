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
      io << ">"
      yield
      io << "</" << name << ">"
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
      def generate(file : String, functions : Array(AST::Prototype))
        output = File.basename(file, ".runic") + ".html"

        File.open(output, "w") do |io|
          document(io, title: File.basename(file)) do |html|
            html.element("div", id: "contents") do
              html.element("h1", File.basename(file))

              html.element("h2", "Functions", id: "#functions")

              functions.each do |proto|
                html.element("article", id: "function-#{proto.name}") do
                  html.element("h3") do
                    html.element("code") { signature(html, proto) }
                  end
                  html.element("p") { html.text proto.documentation }
                end
              end
            end

            sidebar(html) do
              html.element("h2", "Functions")
              functions.each { |proto| sidebar_entry(html, proto) }
            end
          end
        end
      end

      private def signature(html : HTML::Builder, proto : AST::Prototype)
        html.text "def "
        html.element("a", proto.name, href: "#function-#{proto.name}")
        html.text "("
        proto.args.each_with_index do |arg, index|
          html.text ", " unless index == 0
          html.text arg.name
          html.text " : "
          html.element("a", arg.type, class: "type")
        end
        html.text ") : "
        html.element("a", proto.type, class: "type")
      end

      private def document(io : IO, title : String)
        HTML.build(io) do |html|
          html.element("head") do
            html.element("title", title)
            html.element("style") do
              html.raw <<-CSS
                * { font-family: inherit; }
                body {
                  display: flex;
                  flex-direction: column;
                  min-height: 100vh;
                  padding: 0;
                  margin: 0;
                  font: 16px/1.4 normal normal Georgia, serif;
                }
                code { font-family: Menlo, Consolas, Monaco, monospace; }
                h1 { font-size: 2em; }
                h2 { font-size: 1.4em; }
                h3, p { font-size: 1em; margin: 0 0 1em; }
                article { margin-bottom: 2em; }
                #main {
                  display: flex;
                  flex: 1;
                }
                #contents {
                  flex: 1;
                  padding: 1em;
                }
                #contents h1:first-child {
                  margin-top: 0;
                }
                #sidebar {
                  flex: 0 0 12em;
                  order: -1;
                  background: #EEE;
                }
                #sidebar h2 { text-align: center; }
                #sidebar ul {
                  list-style: none;
                  padding-left: 0;
                  margin: 1em 0;
                }
                #sidebar a {
                  display: block;
                  padding: 0 1em;
                }
                CSS
            end
          end

          html.element("body") do
            html.element("div", id: "main") { yield html }
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

      private def sidebar_entry(html : HTML::Builder, proto : AST::Prototype)
        html.element("li") do
          html.element("a", proto.name, href: "#function-#{proto.name}")
        end
      end
    end
  end
end
