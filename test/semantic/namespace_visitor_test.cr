require "../test_helper"

module Runic
  class Semantic
    class NamespaceVisitorTest < Minitest::Test
      def test_expands_module_and_struct_and_method_names
        node = visit <<-RUNIC
        module App
          module Auth
            struct User
              def age; end
              def name; end
            end
            struct Group; end
          end
        end
        RUNIC

        app = node.as(AST::Module)
        assert_equal "App", app.name

        auth = app.modules.first
        assert_equal "App::Auth", auth.name

        assert_equal %w(App::Auth::User App::Auth::Group), auth.structs.map(&.name)
        assert_equal %w(App::Auth::User App::Auth::Group), program.structs.map(&.first)

        user = auth.structs.first
        assert_equal %w(App::Auth::User::age App::Auth::User::name), user.methods.map(&.name)
      end

      def test_expands_struct_method_names
        node = visit <<-RUNIC
        struct User
          def age; end
          def name; end
        end
        RUNIC

        methods = node.as(AST::Struct).methods
        assert_equal "User::age", methods[0].name
        assert_equal "User::name", methods[1].name
      end

      protected def visitors
        @visitor ||= [NamespaceVisitor.new(program)]
      end
    end
  end
end
