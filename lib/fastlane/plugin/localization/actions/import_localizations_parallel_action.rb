require 'shellwords'

module Fastlane
  module Actions
    class ImportLocalizationsParallelAction < Action
      def self.run(params)
        # Join file paths with null sequence to use "xargs -0" options
        # so that 'xargs' can ensure that 'xargs' processes a given filename including even whitespaces
        source_paths = params[:source_paths].map { |x| Shellwords.escape(x) }.join('\0')
        project = Shellwords.escape(params[:project])
        concurrency = Shellwords.escape(params[:concurrency])

        UI.message("Importing localizations from #{source_paths} to #{project} project")

        # This value is used to pass a variable coming from xargs to the command executed.
        xargs_param = "{}"

        # xcodebuild command to import localizations
        xcodebuild = %(xcodebuild -importLocalizations -project #{project} -localizationPath #{xargs_param})

        # In order to distinguish error messages, this script append a filename as perfix to each line of output
        error_logger = %(while read -r error; do echo \\"#{xargs_param}: \\$error\\"; done)

        # 1. List xliff files that you want to import
        # 2. xargs run sub shells that execute xcodebuild in prallel
        sh "echo \"#{source_paths}\" | xargs -0 -L1 -P#{concurrency} -I#{xargs_param} sh -c \"#{xcodebuild} 2>&1 | #{error_logger}\""
      end

      def self.description
        "Import app localizations in parallel with help of xcodebuild -importLocalizations tool"
      end

      def self.authors
        ["vmalyid"]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :source_paths,
                                       env_name: "IMPORTT_LOCALIZATION_SOURCE_PATHS",
                                       description: "The list of source file path of XLIFF files which will be imported",
                                       default_value: [],
                                       optional: false,
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :project,
                                       env_name: "PROJECT",
                                       description: "Project to import localizations to",
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :concurrency,
                                       env_name: "IMPORT_LOCALIZATION_CONCURRENCY",
                                       description: "The number of processes to run xcodebuild with importLocalizations command at the same time",
                                       default_value: 1,
                                       optional: true,
                                       type: Numeric)
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
