# frozen_string_literal: true

# Regression test that proves the `publish` command's book-entity JSON output
# (the file written by Book#save_to_file, the same payload used by
# `./pubdlib.rb publish --identifier ...`) is deterministic: running the
# exact same source data through Book twice must produce byte-identical
# JSON files.
#
# Run from the repository root (relative `require './lib/...'` calls inside
# lib/book.rb depend on it):
#
#   ruby test/book_publish_determinism_test.rb

require 'minitest/autorun'
require 'fileutils'
require 'json'
require 'tmpdir'

REPO_ROOT = File.expand_path('..', __dir__)
Dir.chdir(REPO_ROOT)

require_relative '../lib/book'
require_relative '../lib/ie'

# Minimal stand-in for SeExperimental/Se exposing only what Book, and the
# real Mets instance it builds internally, need to read from a source
# entity. Using fixture METS/MODS/RIGHTS files on disk keeps the real
# Mets parsing logic under test instead of faking it away.
class FakeSe
  FIXTURE_IDENTIFIER = 'test_book_001'

  def identifier
    FIXTURE_IDENTIFIER
  end

  def noid
    'abc123'
  end

  def type
    'book'
  end

  def type_alias
    'books'
  end

  def partner_code
    'partner1'
  end

  def collection_code
    'col1'
  end

  def collections
    [
      {
        title: 'Test Collection',
        name: 'Test Collection',
        identifier: 'col-uuid',
        type: 'dlts_collection',
        language: 'und',
        code: 'col1',
        partner: {
          title: 'Test Partner',
          name: 'Test Partner',
          type: 'dlts_partner',
          language: 'und',
          identifier: 'partner-uuid',
          code: 'partner1'
        }
      }
    ]
  end

  def partners
    collections.map { |c| c[:partner] }
  end

  def handle_url
    'https://hdl.handle.net/123456/abc123'
  end

  def fmds
    []
  end

  # Used by Book#ie_file_path: @se.hash.resource.ies[0].ie_id
  def hash
    { resource: { ies: [{ ie_id: 'ie001' }] } }
  end

  # Stubbed so Mets#representative_image / #sequences don't hit the network.
  # Returns a fixed value so it is NOT itself a source of non-determinism.
  def image_metadata(_image_id)
    { 'width' => 1000, 'height' => 2000 }
  end
end

# Book#initialize always builds an Ie (multi-volume linkage), which parses a
# *different* METS file (the Intellectual Entity wrapper) over the network.
# That concern is independent of entity-JSON determinism, so it is faked out.
class FakeIe
  def books
    []
  end
end

class BookPublishDeterminismTest < Minitest::Test
  def setup
    @fixture_root = File.expand_path('fixtures/rsbe_content', __dir__)
    @tmp_dir = Dir.mktmpdir('pubdlib-book-test')

    $configuration = {
      'RSBE_CONTENT' => @fixture_root,
      'CONTENT_DIR' => @tmp_dir
    }

    FileUtils.mkdir_p("#{@tmp_dir}/books")
  end

  def teardown
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && Dir.exist?(@tmp_dir)
  end

  def test_publish_book_generates_identical_json_on_repeated_runs
    # Simulate two real publish runs happening at different wall-clock
    # moments (e.g. once today, once tomorrow) with the exact same
    # underlying source data. The resulting JSON must be identical.
    first_json = build_book_json_at(Time.at(1_700_000_000))
    second_json = build_book_json_at(Time.at(1_700_086_400)) # 24h later

    assert_equal first_json, second_json,
                 'Publishing the same source entity twice (at different times) produced different JSON. ' \
                 'Likely cause: non-deterministic data (e.g. Time.now timestamps) baked into the entity payload.'
  end

  def test_publish_book_writes_identical_file_on_repeated_runs
    first_path = save_book_to_file_at(Time.at(1_700_000_000))
    first_contents = File.read(first_path)
    File.delete(first_path)

    second_path = save_book_to_file_at(Time.at(1_700_086_400)) # 24h later
    second_contents = File.read(second_path)

    assert_equal first_path, second_path
    assert_equal first_contents, second_contents,
                 'Publishing the same source entity twice wrote different file contents to disk.'
  end

  private

  def build_book_json_at(fixed_time)
    Time.stub(:now, fixed_time) do
      Ie.stub(:new, FakeIe.new) do
        Book.new(FakeSe.new, 'DLTS-TEST-0001').json
      end
    end
  end

  def save_book_to_file_at(fixed_time)
    Time.stub(:now, fixed_time) do
      Ie.stub(:new, FakeIe.new) do
        book = Book.new(FakeSe.new, 'DLTS-TEST-0001')
        book.save_to_file
        "#{@tmp_dir}/books/#{FakeSe::FIXTURE_IDENTIFIER}.en.json"
      end
    end
  end
end
