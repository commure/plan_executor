module Crucible
  module Tests
    class BaseTestScript < BaseTest

      ASSERTION_MAP = {
        # equals	expected (value1 or xpath expression2) actual (value1 or xpath expression2)	Asserts that "expected" is equal to "actual".
        "equals" => :assert_equal,
        # response_code	code (numeric HTTP response code)	Asserts that the response code equals "code".
        "response_code" => :assert_response_code,
        # response_okay	N/A	Asserts that the response code is in the set (200, 201).
        "response_okay" => :assert_response_ok,
        # response_gone	N/A	Asserts that the response code is 410.
        "response_gone" => :assert_response_gone,
        # response_not_found	N/A	Asserts that the response code is 404.
        "response_not_found" => :assert_response_not_found,
        # response_bad	N/A	Asserts that the response code is 400.
        "response_bad" => :assert_response_bad,
        # navigation_links	Bundle	Asserts that the Bundle contains first, last, and next links.
        "navigation_links" => :assert_nagivation_links,
        # resource_type	resourceType (string)	Asserts that the response contained a FHIR Resource of the given "resourceType".
        "resource_type" => :assert_resource_type,
        # valid_content_type	N/A	Asserts that the response contains a "content-type" is either "application/xml+fhir" or "application/json+fhir" and that "charset" is specified as "UTF-8"
        "valid_content_type" => :assert_valid_resource_content_type_present,
        # valid_content_location	N/A	Asserts that the response contains a valid "content-location" header.
        "valid_content_location" => :assert_valid_content_location_present,
        # valid_last_modified	N/A	Asserts that the response contains a valid "last-modified" header.
        "valid_last_modified" => :assert_last_modified_present
      }

      def initialize(testscript, client, client2=nil)
        super(client, client2)
        @testscript = testscript
        define_tests
        load_fixtures
        @id_map = {}
      end

      def author
        @testscript.name
      end

      def description
        @testscript.description
      end

      def id
        @testscript.xmlId
      end

      def title
        id
      end

      def tests
        @testscript.test.map { |test| "#{test.xmlId} #{test.name} test".downcase.tr(' ', '_').to_sym }
      end

      def define_tests
        @testscript.test.each do |test|
          test_method = "#{test.xmlId} #{test.name} test".downcase.tr(' ', '_').to_sym
          define_singleton_method test_method, -> { process_test(test) }
        end
      end

      def load_fixtures
        @fixtures = {}
        @testscript.fixture.each do |fixture|
          @fixtures[fixture.xmlId] = Generator::Resources.new.load_fixture(fixture.uri)
        end
      end

      def process_test(test)
        result = TestResult.new(test.xmlId, test.name, STATUS[:pass], '','')
        begin
          test.operation.each do |op|
            execute_operation op
          end
          # result.update(t.status, t.message, t.data) if !t.nil? && t.is_a?(Crucible::Tests::TestResult)
        rescue AssertionException => e
          result.update(STATUS[:fail], e.message, e.data)
        rescue => e
          result.update(STATUS[:error], "Fatal Error: #{e.message}", e.backtrace.join("\n"))
        end
        if !test.metadata.nil?
          result.requires = test.metadata.requires.map {|r| {resource: r.fhirType, methods: r.operations} } if !test.metadata.requires.empty?
          result.validates = test.metadata.validates.map {|r| {resource: r.fhirType, methods: r.operations} } if !test.metadata.requires.empty?
          result.links = test.metadata.link.map(&:url) if !test.metadata.link.empty?
        end
        result
      end

      def setup
        return if @testscript.setup.blank?
        @testscript.setup.operation.each do |op|
          execute_operation op
        end
      end

      def teardown
        return if @testscript.teardown.blank?
        @testscript.teardown.operation.each do |op|
          execute_operation op
        end
      end

      def execute_operation(operation)
        return if @client.nil?
        case operation.fhirType
        when 'create'
          @last_response = @client.create @fixtures[operation.source]
          @id_map[operation.source] = @last_response.id
        when 'read'
          @last_response = @client.read @fixtures[operation.target].class, @id_map[operation.target]
        when 'delete'
          @client.destroy(FHIR::Condition, @cond1_reply.id) if !@cond1_id.nil?
          @last_response = @client.destroy @fixtures[operation.target].class, @id_map[operation.target]
          @id_map.delete(operation.target)
        when 'assertion'
          assertion = operation.parameter
          if operation.parameter.start_with? "resource_type"
            assertion = operation.parameter.split(":").first
            resource_type = "FHIR::#{operation.parameter.split(":").last}".constantize
          elsif operation.parameter.start_with? "code"
            assertion = operation.parameter.split(":").first
            code = operation.parameter.split(":").last
          end
          if self.methods.include?(ASSERTION_MAP[assertion])
            case assertion
            when "code"
              self.method(ASSERTION_MAP[assertion]).call(@last_response, code)
            when "resource_type"
              self.method(ASSERTION_MAP[assertion]).call(@last_response, resource_type)
            else
              self.method(ASSERTION_MAP[assertion]).call(@last_response)
            end
          else
            raise "Undefined assertion for #{@testscript.name}-#{title}: #{operation.parameter}"
          end
        end
      end

      #
      # def execute_test_method(test_method)
      #   test_item = @testscript.test.select {|t| "#{t.xmlId} #{t.name} test".downcase.tr(' ', '_').to_sym == test_method}.first
      #   result = Crucible::Tests::TestResult.new(test_item.xmlId, test_item.name, Crucible::Tests::BaseTest::STATUS[:skip], '','')
      #   # result.warnings = @warnings  unless @warnings.empty?
      #
      #   result.id = self.object_id.to_s
      #   result.code = test_item.to_xml
      #
      #   result.to_hash.merge!({:test_method => test_method})
      # end

    end
  end
end
