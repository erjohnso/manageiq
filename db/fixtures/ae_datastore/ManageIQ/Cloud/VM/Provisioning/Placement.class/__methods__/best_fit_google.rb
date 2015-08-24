#
# Description: Google Placement
#

def set_property(prov, image, list_method, property)
  return if prov.get_option(property)
  result = prov.send(list_method)
  $evm.log("debug", "#{property} #{result.inspect}")
  object = result.try(:first)
  return unless object

  prov.send("set_#{property}", object)
  $evm.log("info", "Image=[#{image.name}] #{property}=[#{object.name}]")
end

# Get variables
prov     = $evm.root["miq_provision"]
image    = prov.vm_template
raise "Image not specified" if image.nil?

instance_id    = prov.get_option(:instance_type)
raise "Instance Type not specified" if instance_id.nil?
flavor         = $evm.vmdb('flavor').find(instance_id)
$evm.log("debug", "instance id=#{instance_id} name=#{flavor.try(:name)}")

$evm.log("info", "Using GCE for default placement of instance type=[#{flavor.try(:name)}]")
