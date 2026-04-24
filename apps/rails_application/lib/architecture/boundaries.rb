require "prism"
require "set"

module Architecture
  Boundary = Data.define(:name, :type, :paths, :allowed)
  Violation = Data.define(:source, :target, :constant, :file, :line, :column)

  class Boundaries
    DEFAULT_ALLOWED_BY_TYPE = {
      "read_model" => %w[bounded_context],
      "process" => %w[bounded_context],
    }.freeze

    def initialize(boundaries)
      @boundaries = boundaries
      @by_name = boundaries.each_with_object({}) { |b, h| h[b.name] = b }
      @declared = build_declaration_index
    end

    def check
      @boundaries.flat_map { |boundary| check_boundary(boundary) }
    end

    private

    def files_for(paths)
      paths.flat_map { |path| expand_path(path) }
    end

    def expand_path(path)
      File.file?(path) ? [path] : Dir.glob(File.join(path, "**", "*.rb"))
    end

    def build_declaration_index
      @boundaries.each_with_object({}) do |boundary, result|
        declared = Set.new
        files_for(boundary.paths).each do |file|
          collect_declarations(Prism.parse_file(file).value, [], declared)
        end
        result[boundary.name] = declared
      end
    end

    def collect_declarations(node, nesting, declared)
      return if node.nil?

      case node
      when Prism::ModuleNode, Prism::ClassNode
        new_nesting = nesting + node.constant_path.full_name_parts
        declared << new_nesting.join("::")
        collect_declarations(node.body, new_nesting, declared)
      else
        node.compact_child_nodes.each { |c| collect_declarations(c, nesting, declared) }
      end
    end

    def check_boundary(source)
      files_for(source.paths).flat_map { |file| check_file(file, source) }
    end

    def check_file(file, source)
      violations = []
      walk(Prism.parse_file(file).value, [], source, file, violations)
      violations
    end

    def walk(node, nesting, source, file, violations)
      return if node.nil?

      case node
      when Prism::ModuleNode
        new_nesting = nesting + node.constant_path.full_name_parts
        walk(node.body, new_nesting, source, file, violations)
      when Prism::ClassNode
        new_nesting = nesting + node.constant_path.full_name_parts
        walk(node.superclass, new_nesting, source, file, violations)
        walk(node.body, new_nesting, source, file, violations)
      when Prism::ConstantPathNode, Prism::ConstantReadNode
        record_ref(node.full_name_parts, node, nesting, source, file, violations)
      else
        node.compact_child_nodes.each { |c| walk(c, nesting, source, file, violations) }
      end
    end

    def record_ref(ref_parts, node, nesting, source, file, violations)
      fqcn = resolve_fqcn(ref_parts, nesting)
      return if @declared.fetch(source.name).include?(fqcn)

      target = find_boundary_by_prefix(fqcn)
      return unless target
      return if target.name == source.name
      return if source.allowed.include?(target.name)
      return if allowed_by_type?(source, target)

      violations << Violation.new(
        source: source.name,
        target: target.name,
        constant: fqcn,
        file: file,
        line: node.start_line,
        column: node.start_column,
      )
    end

    def resolve_fqcn(ref_parts, nesting)
      (matching_prefix(ref_parts.first, nesting) + ref_parts).join("::")
    end

    def matching_prefix(ref_top, nesting)
      i = nesting.length
      while i > 0
        prefix = nesting[0, i]
        return prefix if any_declared?((prefix + [ref_top]).join("::")) || @by_name.key?((prefix + [ref_top]).join("::"))
        i -= 1
      end
      []
    end

    def any_declared?(fqcn)
      @declared.each_value.any? { |set| set.include?(fqcn) }
    end

    def find_boundary_by_prefix(fqcn)
      first_matching_boundary(fqcn.split("::"))
    end

    def first_matching_boundary(parts)
      i = parts.length
      while i > 0
        boundary = @by_name[parts[0, i].join("::")]
        return boundary if boundary
        i -= 1
      end
      nil
    end

    def allowed_by_type?(source, target)
      DEFAULT_ALLOWED_BY_TYPE.fetch(source.type, []).include?(target.type)
    end
  end
end
