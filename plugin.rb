# frozen_string_literal: true

# name: discourse-hash-lugin
# about: Hash Plugin
# meta_topic_id: 9999
# version: 0.0.1
# authors: Discourse
# url: https://github.com/Nilay1004/hash-plugin.git
# required_version: 2.7.0

enabled_site_setting :plugin_name_enabled

module ::MyPluginModule
  PLUGIN_NAME = "discourse-plugin-name"
end

require_relative "lib/my_plugin_module/engine"

after_initialize do
  # Code which should run after Rails has finished booting
end
