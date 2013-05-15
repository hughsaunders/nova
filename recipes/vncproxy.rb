#
# Cookbook Name:: nova
# Recipe:: vncproxy
#
# Copyright 2012, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "nova::nova-common"
include_recipe "monitoring"


platform_options = node["nova"]["platform"]

(platform_options["nova_vncproxy_packages"].each
+ platform_options["nova_vncproxy_consoleauth_packages"]).each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_overrides"]
  end
end

service platform_options["nova_vncproxy_service"] do
  service_name platform_options["nova_vncproxy_service"]
  supports :status => true, :restart => true
  action [:enable, :start]
  subscribes :restart, "nova_conf[/etc/nova/nova.conf]", :delayed
  subscribes :restart, "template[/etc/nova/logging.conf]", :delayed
end

monitoring_procmon platform_options["nova_vncproxy_service"] do
  service_name=platform_options["nova_vncproxy_service"]
  process_name "nova-novncproxy"
  script_name service_name
end

monitoring_metric "nova-novncproxy-proc" do
  type "proc"
  proc_name "nova-novncproxy"
  proc_regex platform_options["nova_vncproxy_service"]

  alarms(:failure_min => 2.0)
end

service platform_options["nova_vncproxy_consoleauth_service"] do
  service_name platform_options["nova_vncproxy_consoleauth_service"]
  supports :status => true, :restart => true
  action :enable
  subscribes :restart, "nova_conf[/etc/nova/nova.conf]", :delayed
  subscribes :restart, "template[/etc/nova/logging.conf]", :delayed
end

monitoring_procmon "nova-consoleauth" do
  service_name=platform_options["nova_vncproxy_consoleauth_service"]
  pname=platform_options["nova_vncproxy_consoleauth_process_name"]
  process_name pname
  script_name service_name
end

monitoring_metric "nova-consoleauth-proc" do
  type "proc"
  proc_name "nova-consoleauth"
  proc_regex platform_options["nova_vncproxy_consoleauth_service"]

  alarms(:failure_min => 1.0)
end
