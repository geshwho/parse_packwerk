# frozen_string_literal: true

RSpec.describe ParsePackwerk do
  def hashify_violations(violations)
    violations.map { |v| hashify_violation(v) }
  end

  def hashify_violation(v)
    {
      type: v.type,
      to_package_name: v.to_package_name,
      class_name: v.to_package_name,
      files: v.files
    }
  end

  subject(:all_packages) do
    ParsePackwerk.all
  end

  describe '.all' do
    context 'in empty app' do
      it { is_expected.to be_empty }
    end

    context 'in app with a trivial root package' do
      before do
        write_file('package.yml', <<~CONTENTS)
          # This file represents the root package of the application
          # Please validate the configuration using `bin/packwerk validate` (for Rails applications) or running the auto generated
          # test case (for non-Rails projects). You can then use `packwerk check` to check your code.
          
          # Turn on dependency checks for this package
          enforce_dependencies: false
          
          # Turn on privacy checks for this package
          # enforcing privacy is often not useful for the root package, because it would require defining a public interface
          # for something that should only be a thin wrapper in the first place.
          # We recommend enabling this for any new packages you create to aid with encapsulation.
          enforce_privacy: false
          
          # By default the public path will be app/public/, however this may not suit all applications' architecture so
          # this allows you to modify what your package's public path is.
          # public_path: app/public/
          
          # A list of this package's dependencies
          # Note that packages in this list require their own `package.yml` file
          dependencies:
        CONTENTS
      end

      let(:expected_package) do
        ParsePackwerk::Package.new(
          name: '.',
          enforce_dependencies: false,
          enforce_privacy: false,
          dependencies: [],
          metadata: {},
        )
      end

      let(:expected_deprecated_references) do
        ParsePackwerk::DeprecatedReferences.from(Pathname.new('deprecated_references.yml'))
      end

      it 'correctly finds the package YML' do
        expect(expected_package.yml).to eq Pathname.new('package.yml')
      end

      it 'correctly finds the package directory' do
        expect(expected_package.directory).to eq Pathname.new('.')
      end

      it { is_expected.to have_matching_package expected_package, expected_deprecated_references }
    end

    context 'in app that enforces privacy and dependencies' do
      before do
        write_file('packs/package_1/package.yml', <<~CONTENTS)
          enforce_dependencies: true
          enforce_privacy: true
        CONTENTS

        write_file('package.yml', <<~CONTENTS)
          # This file represents the root package of the application
          # Please validate the configuration using `bin/packwerk validate` (for Rails applications) or running the auto generated
          # test case (for non-Rails projects). You can then use `packwerk check` to check your code.
          
          # Turn on dependency checks for this package
          enforce_dependencies: false
          
          # Turn on privacy checks for this package
          # enforcing privacy is often not useful for the root package, because it would require defining a public interface
          # for something that should only be a thin wrapper in the first place.
          # We recommend enabling this for any new packages you create to aid with encapsulation.
          enforce_privacy: false
          
          # By default the public path will be app/public/, however this may not suit all applications' architecture so
          # this allows you to modify what your package's public path is.
          # public_path: app/public/
          
          # A list of this package's dependencies
          # Note that packages in this list require their own `package.yml` file
          dependencies:
        CONTENTS
      end

      let(:expected_root_package) do
        ParsePackwerk::Package.new(
          name: '.',
          enforce_dependencies: false,
          enforce_privacy: false,
          dependencies: [],
          metadata: {},
        )
      end

      let(:expected_root_deprecated_references) do
        ParsePackwerk::DeprecatedReferences.from(Pathname.new('deprecated_references.yml'))
      end

      it { is_expected.to have_matching_package expected_root_package, expected_root_deprecated_references }

      let(:expected_domain_package) do
        ParsePackwerk::Package.new(
          name: 'packs/package_1',
          enforce_dependencies: true,
          enforce_privacy: true,
          dependencies: [],
          metadata: {},
        )
      end

      let(:expected_domain_package_deprecated_references) do
        ParsePackwerk::DeprecatedReferences.from(Pathname.new('packs/package_1/deprecated_references.yml'))
      end

      it 'correctly finds the package YML' do
        expect(expected_domain_package.yml).to eq Pathname.new('packs/package_1/package.yml')
      end

      it 'correctly finds the package directory' do
        expect(expected_domain_package.directory).to eq Pathname.new('packs/package_1')
      end

      it { is_expected.to have_matching_package expected_domain_package, expected_domain_package_deprecated_references }
    end

    context 'in app that has metadata' do
      before do
        write_file('packs/package_1/package.yml', <<~CONTENTS)
          enforce_dependencies: true
          enforce_privacy: true
          metadata:
            string_key: this_is_a_string
            obviously_a_boolean_key: false
            not_obviously_a_boolean_key: no
            numeric_key: 123
        CONTENTS

        write_file('package.yml', <<~CONTENTS)
          # This file represents the root package of the application
          # Please validate the configuration using `bin/packwerk validate` (for Rails applications) or running the auto generated
          # test case (for non-Rails projects). You can then use `packwerk check` to check your code.
          
          # Turn on dependency checks for this package
          enforce_dependencies: false
          
          # Turn on privacy checks for this package
          # enforcing privacy is often not useful for the root package, because it would require defining a public interface
          # for something that should only be a thin wrapper in the first place.
          # We recommend enabling this for any new packages you create to aid with encapsulation.
          enforce_privacy: false
          
          # By default the public path will be app/public/, however this may not suit all applications' architecture so
          # this allows you to modify what your package's public path is.
          # public_path: app/public/
          
          # A list of this package's dependencies
          # Note that packages in this list require their own `package.yml` file
          dependencies:
        CONTENTS
      end

      let(:expected_root_package) do
        ParsePackwerk::Package.new(
          name: '.',
          enforce_dependencies: false,
          enforce_privacy: false,
          dependencies: [],
          metadata: {},
        )
      end

      let(:expected_root_deprecated_refereces) do
        ParsePackwerk::DeprecatedReferences.from(Pathname.new('deprecated_references.yml'))
      end

      it { is_expected.to have_matching_package expected_root_package, expected_root_deprecated_refereces }

      let(:expected_domain_package) do
        ParsePackwerk::Package.new(
          name: 'packs/package_1',
          enforce_dependencies: true,
          enforce_privacy: true,
          dependencies: [],
          metadata: {
            'string_key' => 'this_is_a_string',
            'obviously_a_boolean_key' => false,
            'not_obviously_a_boolean_key' => false,
            'numeric_key' => 123,
          },
        )
      end

      let(:expected_deprecated_references) do
        ParsePackwerk::DeprecatedReferences.from(Pathname.new('packs/package_1/deprecated_references.yml'))
      end

      it { is_expected.to have_matching_package expected_domain_package, expected_deprecated_references }
    end

    context 'in app that has violations' do
      before do
        write_file('packs/package_2/deprecated_references.yml', <<~CONTENTS)
          # This file contains a list of dependencies that are not part of the long term plan for ..
          # We should generally work to reduce this list, but not at the expense of actually getting work done.
          #
          # You can regenerate this file using the following command:
          #
          # bundle exec packwerk update-deprecations .
          ---
          packs/package_1:
            "SomeConstant":
              violations:
              - dependency
              files:
              - packs/package_1/lib/some_file.rb
          '.':
            "SomeRootConstant":
              violations:
              - dependency
              files:
              - root_file.rb
            "SomeOtherRootConstant":
              violations:
              - dependency
              files:
              - root_file.rb
        CONTENTS

        write_file('packs/package_2/package.yml', <<~CONTENTS)
          enforce_dependencies: true
          enforce_privacy: true
        CONTENTS

        write_file('packs/package_1/deprecated_references.yml', <<~CONTENTS)
          # This file contains a list of dependencies that are not part of the long term plan for ..
          # We should generally work to reduce this list, but not at the expense of actually getting work done.
          #
          # You can regenerate this file using the following command:
          #
          # bundle exec packwerk update-deprecations .
          ---
          packs/package_2:
            "SomePrivateConstant":
              violations:
              - privacy
              files:
              - packs/package_2/lib/some_other_file.rb
        CONTENTS

        write_file('packs/package_1/package.yml', <<~CONTENTS)
          enforce_dependencies: true
          enforce_privacy: true
          dependencies:
            - packs/package_2
        CONTENTS

        write_file('deprecated_references.yml', <<~CONTENTS)
          # This file contains a list of dependencies that are not part of the long term plan for ..
          # We should generally work to reduce this list, but not at the expense of actually getting work done.
          #
          # You can regenerate this file using the following command:
          #
          # bundle exec packwerk update-deprecations .
          ---
          packs/package_1:
            "SomeConstant":
              violations:
              - dependency
              files:
              - some_file.rb
          packs/package_2:
            "SomePrivateConstant":
              violations:
              - privacy
              files:
              - some_other_file.rb
              - path/to/file.rb
              - extended/path/to/file.rb
        CONTENTS

        write_file('package.yml', <<~CONTENTS)
          # This file represents the root package of the application
          # Please validate the configuration using `bin/packwerk validate` (for Rails applications) or running the auto generated
          # test case (for non-Rails projects). You can then use `packwerk check` to check your code.
          
          # Turn on dependency checks for this package
          enforce_dependencies: true
          
          # Turn on privacy checks for this package
          # enforcing privacy is often not useful for the root package, because it would require defining a public interface
          # for something that should only be a thin wrapper in the first place.
          # We recommend enabling this for any new packages you create to aid with encapsulation.
          enforce_privacy: false
          
          # By default the public path will be app/public/, however this may not suit all applications' architecture so
          # this allows you to modify what your package's public path is.
          # public_path: app/public/
          
          # A list of this package's dependencies
          # Note that packages in this list require their own `package.yml` file
          dependencies:
            - packs/package_2
        CONTENTS
      end

      let(:expected_root_package) do
        ParsePackwerk::Package.new(
          name: '.',
          enforce_dependencies: true,
          enforce_privacy: false,
          dependencies: ['packs/package_2'],
          metadata: {},
        )
      end

      let(:expected_deprecated_references) do
        ParsePackwerk::DeprecatedReferences.new(
          pathname: Pathname.new('deprecated_references.yml'),
          violations: [
            ParsePackwerk::Violation.new(
              type: 'dependency',
              to_package_name: 'packs/package_1',
              class_name: 'SomeConstant',
              files: ['some_file.rb']
            ),
            ParsePackwerk::Violation.new(
              type: 'privacy',
              to_package_name: 'packs/package_2',
              class_name: 'SomePrivateConstant',
              files: ['some_other_file.rb', 'path/to/file.rb', 'extended/path/to/file.rb']
            ),
          ],
        )
      end

      it { is_expected.to have_matching_package expected_root_package, expected_deprecated_references }

      let(:expected_domain_package_1) do
        ParsePackwerk::Package.new(
          name: 'packs/package_1',
          enforce_dependencies: true,
          enforce_privacy: true,
          dependencies: ['packs/package_2'],
          metadata: {},
        )
      end

      let(:expected_deprecated_references_1) do
        ParsePackwerk::DeprecatedReferences.new(
          pathname: Pathname.new('packs/package_1/deprecated_references.yml'),
          violations: [
            ParsePackwerk::Violation.new(
              type: 'privacy',
              to_package_name: 'packs/package_2',
              class_name: 'SomePrivateConstant',
              files: ['packs/package_2/lib/some_other_file.rb']
            ),
          ],
        )
      end

      it { is_expected.to have_matching_package expected_domain_package_1, expected_deprecated_references_1 }

      let(:expected_domain_package_2) do
        ParsePackwerk::Package.new(
          name: 'packs/package_2',
          enforce_dependencies: true,
          enforce_privacy: true,
          dependencies: [],
          metadata: {},
        )
      end

      let(:expected_domain_package_deprecated_references_2) do
        ParsePackwerk::DeprecatedReferences.new(
          pathname: Pathname.new('packs/package_2/deprecated_references.yml'),
          violations: [
            ParsePackwerk::Violation.new(
              type: 'dependency',
              to_package_name: 'packs/package_1',
              class_name: 'SomeConstant',
              files: ['packs/package_1/lib/some_file.rb']
            ),
            ParsePackwerk::Violation.new(
              type: 'dependency',
              to_package_name: '.',
              class_name: 'SomeRootConstant',
              files: ['root_file.rb']
            ),
            ParsePackwerk::Violation.new(
              type: 'dependency',
              to_package_name: '.',
              class_name: 'SomeOtherRootConstant',
              files: ['root_file.rb']
            ),
          ],
        )
      end

      it { is_expected.to have_matching_package expected_domain_package_2, expected_domain_package_deprecated_references_2 }
    end

    context 'in an app that has specified package paths' do
      context 'app has specified packs in a specific folder' do
        before do
          write_file('packwerk.yml', <<~CONTENTS)
            package_paths:
              - 'packs/*'
          CONTENTS

          write_file('package.yml', <<~CONTENTS)
            enforce_dependencies: false
            enforce_privacy: false
          CONTENTS

          write_file('packs/my_pack/package.yml', <<~CONTENTS)
            enforce_dependencies: false
            enforce_privacy: false
          CONTENTS

          write_file('app/services/my_non_package_location/package.yml', <<~CONTENTS)
            enforce_dependencies: false
            enforce_privacy: false
          CONTENTS
        end

        it 'includes the correct set of packages' do
          expect(all_packages.count).to eq 2
          expect(all_packages.find{|p| p.name == '.'}).to_not be_nil
          expect(all_packages.find{|p| p.name == 'packs/my_pack'}).to_not be_nil
        end
      end

      context 'app has excluded packs in a specific folder' do
        before do
          write_file('packwerk.yml', <<~CONTENTS)
            package_paths:
              - 'packs/*'
            exclude:
              - 'packs/pack_to_ignore/*'
          CONTENTS

          write_file('package.yml', <<~CONTENTS)
            enforce_dependencies: false
            enforce_privacy: false
          CONTENTS

          write_file('packs/my_pack/package.yml', <<~CONTENTS)
            enforce_dependencies: false
            enforce_privacy: false
          CONTENTS

          write_file('packs/pack_to_ignore/package.yml', <<~CONTENTS)
            enforce_dependencies: false
            enforce_privacy: false
          CONTENTS

          write_file('app/services/my_non_package_location/package.yml', <<~CONTENTS)
            enforce_dependencies: false
            enforce_privacy: false
          CONTENTS
        end

        it 'includes the correct set of packages' do
          expect(all_packages.count).to eq 2
          expect(all_packages.find{|p| p.name == '.'}).to_not be_nil
          expect(all_packages.find{|p| p.name == 'packs/my_pack'}).to_not be_nil
        end
      end
    end

    context 'in an app with no root package' do
      before do
        write_file('package.yml', <<~CONTENTS)
          enforce_dependencies: false
          enforce_privacy: false
        CONTENTS

        write_file('packs/my_pack/package.yml', <<~CONTENTS)
          enforce_dependencies: false
          enforce_privacy: false
        CONTENTS
      end

      it 'includes the correct set of packages' do
        expect(all_packages.count).to eq 2
        expect(all_packages.find{|p| p.name == '.'}).to_not be_nil
        expect(all_packages.find{|p| p.name == 'packs/my_pack'}).to_not be_nil
      end
    end
  end

  describe '.yml' do
    let(:configuration) { ParsePackwerk.yml }

    describe 'exclude' do
      subject { configuration.exclude }

      context 'when the configuration file is not present' do
        it { is_expected.to contain_exactly(Bundler.bundle_path.join("**").to_s, "{bin,node_modules,script,tmp,vendor}/**/*") }
      end

      context 'configuration is present' do
        before do
          write_file('packwerk.yml', <<~CONTENTS)
            exclude:
              - 'a/b/**/c.rb'
          CONTENTS
        end

        it { is_expected.to contain_exactly(Bundler.bundle_path.join("**").to_s, 'a/b/**/c.rb') }
      end

      context 'when the exclude option is not defined' do
        before do
          write_file('packwerk.yml', <<~CONTENTS)
            # empty file
          CONTENTS
        end

        it { is_expected.to contain_exactly(Bundler.bundle_path.join("**").to_s, "{bin,node_modules,script,tmp,vendor}/**/*") }
      end

      context 'when the exclude option is a string and not a list of strings' do
        before do
          write_file('packwerk.yml', <<~CONTENTS)
            exclude: 'a/b/**/c.rb'
          CONTENTS
        end
        it { is_expected.to contain_exactly(Bundler.bundle_path.join("**").to_s, 'a/b/**/c.rb') }
      end
    end

    describe 'package_paths' do
      subject { configuration.package_paths }

      context 'when the configuration file is not present' do
        it { is_expected.to contain_exactly("**/", '.') }
      end

      context 'configuration is present' do
        before do
          write_file('packwerk.yml', <<~CONTENTS)
            package_paths:
              - 'packs/*'
          CONTENTS
        end

        it { is_expected.to contain_exactly('packs/*', '.') }
      end

      context 'when the package paths option is not defined' do
        before do
          write_file('packwerk.yml', <<~CONTENTS)
            # empty file
          CONTENTS
        end

        it { is_expected.to contain_exactly("**/", '.') }
      end

      context 'when the package paths option is a string and not a list of strings' do
        before do
          write_file('packwerk.yml', <<~CONTENTS)
            package_paths: 'packs/*'
          CONTENTS
        end
        it { is_expected.to contain_exactly('packs/*', '.') }
      end
    end
  end

  describe 'ParsePackwerk.write_package_yml' do
    let(:package_dir) { Pathname.new('packs/example_pack') }
    let(:package_yml) { package_dir.join('package.yml') }
    let(:deprecated_references_yml) { package_dir.join('deprecated_references.yml') }

    def build_pack(dependencies: [], metadata: {})
      ParsePackwerk::Package.new(
        name: package_dir.to_s,
        enforce_dependencies: true,
        enforce_privacy: true,
        dependencies: dependencies,
        metadata: metadata
      )
    end

    def pack_as_hash(package)
      {
        name: package.name,
        enforce_dependencies: package.enforce_dependencies,
        enforce_privacy: package.enforce_privacy,
        dependencies: package.dependencies,
        metadata: package.metadata,
      }
    end

    context 'a simple package' do
      let(:package) { build_pack }

      it 'writes the right package' do
        ParsePackwerk.write_package_yml!(package)
        expect(package_yml.read).to eq <<~PACKAGEYML
          enforce_dependencies: true
          enforce_privacy: true
        PACKAGEYML

        expect(all_packages.count).to eq 1
        expect(pack_as_hash(all_packages.first)).to eq pack_as_hash(package)
      end
    end

    context 'package with dependencies' do
      let(:package) do
        build_pack(dependencies: ['my_other_pack1', 'my_other_pack2'])
      end

      it 'writes the right package' do
        ParsePackwerk.write_package_yml!(package)
        expect(package_yml.read).to eq <<~PACKAGEYML
          enforce_dependencies: true
          enforce_privacy: true
          dependencies:
            - my_other_pack1
            - my_other_pack2
        PACKAGEYML

        expect(all_packages.count).to eq 1
        expect(pack_as_hash(all_packages.first)).to eq pack_as_hash(package)
      end
    end

    context 'package with metadata' do
      let(:package) do
        build_pack(metadata: {
          'owner' => 'Mission > Team',
          'protections' => { 'prevent_untyped_api' => 'fail_if_any', 'prevent_violations' => false },
        })
      end

      it 'writes the right package' do
        ParsePackwerk.write_package_yml!(package)

        expect(package_yml.read).to eq <<~PACKAGEYML
          enforce_dependencies: true
          enforce_privacy: true
          metadata:
            owner: Mission > Team
            protections:
              prevent_untyped_api: fail_if_any
              prevent_violations: false
        PACKAGEYML

        expect(all_packages.count).to eq 1
        expect(pack_as_hash(all_packages.first)).to eq pack_as_hash(package)
      end
    end
  end
end
