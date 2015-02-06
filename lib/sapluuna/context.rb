class Sapluuna
  class Context
    attr_reader :discovered_variables, :variables

    RootDirectory = '.'

    class VariableMissing < Error; end

    def initialize opts
      @opts                 = opts.dup
      @discover_variables   = opts.delete :discover_variables
      @variables            = (opts.delete(:variables) or {})
      @root_directory       = (opts.delete(:root_directory) or RootDirectory)
      @output               = ''
      @discovered_variables = []
    end

    def text value
      @output << value
    end

    def code value
      @output << eval(value).to_s
    end

    def str
      @output
    end

    def are value
      [:are, value]
    end

    def is value
      [:is, value]
    end

    def silent *args
      ""
    end

    private

    def import file
      template = File.read resolve_file(file)
      @opts[:variables]      = @variables
      @opts[:root_directory] = @root_directory.dup
      Log.debug "importing #{file}"
      sapl     = Sapluuna.new @opts
      output   = sapl.parse template
      @discovered_variables += sapl.discovered_variables
      add_indent output.lines, @output.lines.last
    end

    def resolve_file file
      # should we avoid ../../../etc/passwd style input here?
      # why? we control templates?
      File.join @root_directory, file
    end

    def add_indent output, indent_hint
      indent_size = indent_hint.match(/\A\s*/)[0].size
      first_line  = output[0]
      output = output[1..-1].map { |line| ' ' * indent_size + line } if output.size > 1
      output.unshift(first_line).join
    end

    def method_missing method, *args
      if Array === args.first
        value = args.first.last
        case args.first.first
        when :is
          @variables[method] = value
        when :are
          @variables[method] = value.to_s.strip.split(/\s+/)
        end
        ""
      elsif @variables[method]
        @variables[method]
      else
        if @discover_variables
          @discovered_variables << method
          ""
        else
          raise VariableMissing, "variable '#{method}' required, but not given"
        end
      end
    end
  end
end
